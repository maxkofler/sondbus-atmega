#![no_std]
#![no_main]
#![feature(abi_avr_interrupt)]
#![feature(inline_const)]

use core::panic::{self, PanicInfo};

use arduino_hal::{delay_ms, hal::usart::Event, pac::USART0, pins, Peripherals};
use avr_device::interrupt;
use embedded_time::{
    duration::{Generic, Seconds},
    fixed_point::FixedPoint,
    rate::Fraction,
    Clock,
};
use sondbus::{ringbuf::RingBuffer, Slave};

static mut BUFFER: Option<RingBuffer<u8, 0x10>> = None;

#[panic_handler]
fn panic_handler(_panic_info: &PanicInfo) -> ! {
    let dp = unsafe { Peripherals::steal() };
    let pins = pins!(dp);

    let mut led = pins.d13.into_output();

    loop {
        led.toggle();
        delay_ms(50);
    }
}

struct TC1Clk {
    counter: u64,
}

impl Clock for TC1Clk {
    type T = u64;

    const SCALING_FACTOR: Fraction = Fraction::new(1, 2_000_000);

    fn try_now(&self) -> Result<embedded_time::Instant<Self>, embedded_time::clock::Error> {
        todo!()
    }
}

#[arduino_hal::entry]
fn main() -> ! {
    let dp = arduino_hal::Peripherals::take().unwrap();
    let pins = arduino_hal::pins!(dp);

    dp.TC1.tccr1b.write(|f| f.cs1().prescale_8());

    let buffer = [0u8; 0x10];
    let buffer = RingBuffer::new(buffer);
    unsafe { BUFFER = Some(buffer) }

    let mut serial = arduino_hal::default_serial!(dp, pins, 1_000_000);

    serial.listen(Event::RxComplete);

    unsafe { interrupt::enable() };

    let mut clock = TC1Clk { counter: 0 };

    let mut led = pins.d13.into_output();

    let mut slave = Slave::new();

    let mut last_secs = 0;

    loop {
        let time = dp.TC1.tcnt1.read().bits();
        dp.TC1.tcnt1.write(|f| f.bits(0));
        clock.counter += time as u64;

        let generic = Generic::new(clock.counter, Fraction::new(1, 2_000_000));
        let secs = Seconds::<u32>::try_from(generic).unwrap();

        if secs.integer() > last_secs {
            led.toggle();
            last_secs = secs.integer();
        }

        if let Some(buffer) = unsafe { &mut BUFFER } {
            if let Some(ret) = slave.handle_mut(buffer.pop().cloned()) {
                serial.write_byte(ret);
            }
        }
    }
}

#[avr_device::interrupt(atmega2560)]
fn USART0_RX() {
    let x = unsafe { &(*USART0::ptr()) };

    if x.ucsr0a.read().rxc0().bit() {
        unsafe {
            if let Some(buffer) = &mut BUFFER {
                buffer.push(x.udr0.read().bits());
            }
        }
    }
}
