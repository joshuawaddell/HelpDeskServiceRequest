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
    public class EditModel : PageModel
    {
        private readonly HelpDeskServiceRequest.Data.HelpDeskServiceRequestContext _context;

        public EditModel(HelpDeskServiceRequest.Data.HelpDeskServiceRequestContext context)
        {
            _context = context;
        }

        [BindProperty]
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

        // To protect from overposting attacks, enable the specific properties you want to bind to.
        // For more details, see https://aka.ms/RazorPagesCRUD.
        public async Task<IActionResult> OnPostAsync()
        {
            if (!ModelState.IsValid)
            {
                return Page();
            }

            _context.Attach(ServiceRequest).State = EntityState.Modified;

            try
            {
                await _context.SaveChangesAsync();
            }
            catch (DbUpdateConcurrencyException)
            {
                if (!ServiceRequestExists(ServiceRequest.ID))
                {
                    return NotFound();
                }
                else
                {
                    throw;
                }
            }

            return RedirectToPage("./Index");
        }

        private bool ServiceRequestExists(int id)
        {
            return _context.ServiceRequest.Any(e => e.ID == id);
        }
    }
}
