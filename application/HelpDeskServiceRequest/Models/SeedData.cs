using Microsoft.EntityFrameworkCore;
using HelpDeskServiceRequest.Data;

namespace HelpDeskServiceRequest.Models
{
    public static class SeedData
    {
        public static void Initialize(IServiceProvider serviceProvider)
        {
            using (var context = new HelpDeskServiceRequestContext(
                serviceProvider.GetRequiredService<
                    DbContextOptions<HelpDeskServiceRequestContext>>()))
            {
                if (context == null || context.ServiceRequest == null)
                {
                    throw new ArgumentNullException("Null HelpDeskServiceRequestContext");
                }

                // Look for any service requests.
                if (context.ServiceRequest.Any())
                {
                    return;   // DB has been seeded
                }

                context.ServiceRequest.AddRange(
                    new ServiceRequest
                    {
                        Title = "Printer is not printing",
                        Status = "New",
                        RequestDate = DateTime.Parse("2022-2-7"),
                        Description = "After system reboot, unable to print to printer.",
                        Technician = "",
                        Notes = "",
                    },

                    new ServiceRequest
                    {
                        Title = "Unable to access searchengine.com",
                        Status = "Open",
                        RequestDate = DateTime.Parse("2022-2-2"),
                        Description = "Unable to access searchengine.com from multiple browsers.",
                        Technician = "Dave",
                        Notes = "Instructed user to clear history and cookies and report back with status.",
                    },

                    new ServiceRequest
                    {
                        Title = "Help Desk Service Request system is down",
                        Status = "Open",
                        RequestDate = DateTime.Parse("2022-2-5"),
                        Description = "I am unable to access the Help Desk Service Request system to submit a ticket. Please resote access to the system.",
                        Technician = "Natasha",
                        Notes = "You have got to be kidding me.",
                    },

                    new ServiceRequest
                    {
                        Title = "Cell phone needs to be configured for access to email",
                        Status = "New",
                        RequestDate = DateTime.Parse("2022-2-8"),
                        Description = "I just got a new phone and need help configuring it for access to company email. Yes I read the document, but I still need help.",
                        Technician = "",
                        Notes = "",
                    },

                    new ServiceRequest
                    {
                        Title = "Replacement UPS",
                        Status = "Closed",
                        RequestDate = DateTime.Parse("2022-2-1"),
                        CompletionDate = DateTime.Parse("2022-2-2"),
                        Description = "My UPS started beeping the other day after the power surge in the building. Can you please replace the battery or the unit?",
                        Technician = "Jennifer",
                        Notes = "Replaced user's UPS battery. Opened RMA with manufacturer as battery was within warranty limits.",
                    }
                );
                context.SaveChanges();
            }
        }
    }
}