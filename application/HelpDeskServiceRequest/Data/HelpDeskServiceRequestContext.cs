#nullable disable
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using HelpDeskServiceRequest.Models;

namespace HelpDeskServiceRequest.Data
{
    public class HelpDeskServiceRequestContext : DbContext
    {
        public HelpDeskServiceRequestContext (DbContextOptions<HelpDeskServiceRequestContext> options)
            : base(options)
        {
        }

        public DbSet<HelpDeskServiceRequest.Models.ServiceRequest> ServiceRequest { get; set; }
    }
}
