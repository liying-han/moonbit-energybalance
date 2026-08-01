///|
fn main {
  let water = @energy.water_liquid()
  let feed = @energy.Stream::pure(
    id="demo-feed",
    substance=water,
    molar_flow=2.0,
    temperature=298.15,
  )
  let heated = @energy.heater(feed, 348.15)
  println("moonbit-energybalance demo")
  println("feed molar flow: \{feed.molar_flow()} mol/s")
  println("heater duty: \{heated.duty.round()} W")
}
