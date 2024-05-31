import os
import re
import win32com.client

def report_init(mail_body: str, receivers: str, sub_receivers: str, mail_subject: str, attachment: str):
    outlook = win32com.client.Dispatch("Outlook.Application")
    #Outlook Item type
    olItem = {
        "olMailItem": 0,
        "olAppointmentItem" : 1
    }
    message = outlook.CreateItem(olItem.get("olMailItem"))

    message.Body = mail_body
    message.To = receivers
    message.CC = sub_receivers
    message.Subject = mail_subject
    message.Attachments.Add(attachment)
    return message

def get_latest_WR_report_info(report_dir: str) -> tuple:
    """
    Format of report: HSSD_HSSS5_LongTruong_wk15_2024.pptx
    """
    list_of_file = []
    for report in os.scandir(report_dir):
        if report.is_file() and re.match("HSSD_HSSS5_LongTruong_wk[0-9]{2}_[0-9]{4}", report.name):
            list_of_file.append(report.name)
    list_of_file.sort(reverse=True)
    latest_report = list_of_file[0]
    report_path = os.path.join(report_dir, latest_report_name)
    current_week = latest_report.split("_")[3].strip("wk")
    return latest_report, report_path, current_week

def main():
    # Change reporter's name to your name
    mail_body = \
    """\
<Body here>
    """

    #Get location of weekly_report file
    report_dir = "C:\\Users\\longtruong\\Desktop\\Weekly Report\\Wrap\\2024"
    latest_report, report_path, current_week = get_latest_report_info(report_dir=report_dir)

    # Change receiver mails
    receivers = "<receivers> - separated by semicolons"

    # Change reporter's name
    sub_receivers = "<sub-receivers/CC> - separated by semicolons"

    #Change Senser and Week number
    subject = f"<Subject>"  
    
    mail = report_init(mail_body=mail_body,
                       receivers=receivers,
                       sub_receivers=sub_receivers,
                       mail_subject=subject,
                       attachment=report_path)
    mail.Display(True)
    #mail.Send()         #Uncomment this if you want the script to automatically send email

if __name__ == "__main__":
    main()