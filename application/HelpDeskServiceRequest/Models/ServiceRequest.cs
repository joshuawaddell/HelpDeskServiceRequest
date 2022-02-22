using System.ComponentModel.DataAnnotations;

namespace HelpDeskServiceRequest.Models
{
    public class ServiceRequest
    {
        public int ID { get; set; }
        public string Title { get; set; } = string.Empty;

        public string Status { get; set; } = string.Empty;

        [DataType(DataType.Date)]
        [Display(Name = "Request Date")]
        public DateTime RequestDate { get; set; }

        [Display(Name = "Completion Date")]
        public DateTime? CompletionDate { get; set; }

        public string Description { get; set; } = string.Empty;
        public string Technician { get; set; } = string.Empty;        
        public string Notes { get; set; } = string.Empty;
    }
}
