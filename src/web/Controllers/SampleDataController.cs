using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using System.Net.Http;
using System.Net.Http.Headers;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Http;

namespace web.Controllers
{
    [Route("api/[controller]")]
    public class SampleDataController : Controller
    {
		private HttpClient _httpClient = new HttpClient() {BaseAddress = new Uri(Environment.GetEnvironmentVariable("WEATHER_SERVICE_ENDPOINT"))};
		
        [HttpGet("[action]")]
        public async Task WeatherForecasts()
        {
            var queryString = Request.QueryString;
			var response = await _httpClient.GetAsync(queryString.Value);
			var content = await response.Content.ReadAsStringAsync();

			Response.StatusCode = (int)response.StatusCode;
			Response.ContentType = response.Content.Headers.ContentType.ToString();
			Response.ContentLength = response.Content.Headers.ContentLength;

			await Response.WriteAsync(content);
        }
    }
}
