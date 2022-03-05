#nullable disable
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.AspNetCore.Mvc.Rendering;
using Microsoft.EntityFrameworkCore;
using HelpDeskServiceRequest.Data;
using HelpDeskServiceRequest.Models;

namespace HelpDeskServiceRequest.Pages.ServiceRequests
{
    public class IndexModel : PageModel
    {
        private readonly HelpDeskServiceRequest.Data.HelpDeskServiceRequestContext _context;

        public IndexModel(HelpDeskServiceRequest.Data.HelpDeskServiceRequestContext context)
        {
            _context = context;
        }

        public IList<ServiceRequest> ServiceRequest { get;set; }
        [BindProperty(SupportsGet = true)]
        public string SearchString { get; set; }
        public SelectList Status { get; set; }
        [BindProperty(SupportsGet = true)]
        public string Open { get; set; }

        public async Task OnGetAsync()
        {
            // using System.Linq
            var serviceRequests = from m in _context.ServiceRequest
                         select m;
            if (!string.IsNullOrEmpty(SearchString))
            {
                serviceRequests = serviceRequests.Where(s => s.Status.Contains(SearchString));
            }

            ServiceRequest = await serviceRequests.ToListAsync();
        }
    }
}
