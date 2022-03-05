using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace HelpDeskServiceRequest.Migrations
{
    public partial class StatusUpdate : Migration
    {
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "Status",
                table: "ServiceRequest",
                type: "nvarchar(max)",
                nullable: false,
                defaultValue: "");
        }

        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "Status",
                table: "ServiceRequest");
        }
    }
}
