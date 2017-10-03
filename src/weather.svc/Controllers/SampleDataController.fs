namespace weather.svc.Controllers

open System
open System.Collections.Generic
open System.Linq
open System.Threading.Tasks
open Microsoft.AspNetCore.Mvc

type WeatherForecast () =

    member val DateFormatted = "" with get, set

    member val TemperatureC = 0 with get, set

    member val Summary = "" with get, set

    member this.TemperatureF with get () = 32 + int (float this.TemperatureC / 0.5556)

[<Route("api/[controller]")>]
type SampleDataController () =
    inherit Controller()

    static let Summaries = 
        [|"Freezing"; "Bracing"; "Chilly"; "Cool"; "Mild"; "Warm"; "Balmy"; "Hot"; "Sweltering"; "Scorching"|]

    [<HttpGet("[action]")>]
    member this.WeatherForecasts() =
        let rng = new Random()
        seq { for i in 1 .. 15 do yield new WeatherForecast (DateFormatted = DateTime.Now.AddDays(float i).ToString("d"), TemperatureC = rng.Next(-20, 55), Summary = Summaries.[rng.Next(Summaries.Length)]) }