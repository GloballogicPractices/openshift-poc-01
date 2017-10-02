namespace weather.svc.Controllers

open System
open System.Collections.Generic
open System.Linq
open System.Threading.Tasks
open Microsoft.AspNetCore.Mvc

[<Route("api/[controller]")>]
type PingController () =
    inherit Controller()

    [<HttpGet>]
    member this.Get() =
        [|"OK"|]
