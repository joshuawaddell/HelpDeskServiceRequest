#nullable disable
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.EntityFrameworkCore;
using HelpDeskServiceRequest.Data;
using HelpDeskServiceRequest.Models;

namespace HelpDeskServiceRequest.Pages.ServiceRequests
{
    public class DetailsModel : PageModel
    {
        private readonly HelpDeskServiceRequest.Data.HelpDeskServiceRequestContext _context;

        public DetailsModel(HelpDeskServiceRequest.Data.HelpDeskServiceRequestContext context)
        {
            _context = context;
        }

        public ServiceRequest ServiceRequest { get; set; }

        public async Task<IActionResult> OnGetAsync(int? id)
        {
            if (id == null)
            {
                return NotFound();
            }

            ServiceRequest = await _context.ServiceRequest.FirstOrDefaultAsync(m => m.ID == id);

            if (ServiceRequest == null)
            {
                return NotFound();
            }
            return Page();
        }
    }
}
