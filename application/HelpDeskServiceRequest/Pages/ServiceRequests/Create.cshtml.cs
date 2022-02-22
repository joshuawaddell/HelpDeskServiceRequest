#nullable disable
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.AspNetCore.Mvc.Rendering;
using HelpDeskServiceRequest.Data;
using HelpDeskServiceRequest.Models;

namespace HelpDeskServiceRequest.Pages.ServiceRequests
{
    public class CreateModel : PageModel
    {
        private readonly HelpDeskServiceRequest.Data.HelpDeskServiceRequestContext _context;

        public CreateModel(HelpDeskServiceRequest.Data.HelpDeskServiceRequestContext context)
        {
            _context = context;
        }

        public IActionResult OnGet()
        {
            return Page();
        }

        [BindProperty]
        public ServiceRequest ServiceRequest { get; set; }

        // To protect from overposting attacks, see https://aka.ms/RazorPagesCRUD
        public async Task<IActionResult> OnPostAsync()
        {
            if (!ModelState.IsValid)
            {
                return Page();
            }

            ServiceRequest.RequestDate = DateTime.Now;

            ServiceRequest.Status = "New";

            _context.ServiceRequest.Add(ServiceRequest);
            await _context.SaveChangesAsync();

            return RedirectToPage("./Index");
        }
    }
}
