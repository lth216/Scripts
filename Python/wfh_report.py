import win32com.client
import datetime
import re
import sys

class Outlook():
    email = "long.truong.wh@renesas.com"
    
    def connect_to_Outlook(cls):
        cls.outlook = win32com.client.Dispatch("Outlook.Application")
        mapi = cls.outlook.GetNameSpace("MAPI")
        root_folder = mapi.Folders[cls.email]
        return root_folder

    def get_sent_mails(cls):
        sent_emails = cls.connect_to_Outlook().Folders["Sent Items"].Items
        return sent_emails

    def get_wfh_mails(cls, date, filter_pattern):
        ls = []
        mail_info = {}
        messages = cls.get_sent_mails()
        message = messages.GetLast()
        date_sent = message.SentOn.strftime("%Y-%m-%d")
        if re.search(filter_pattern, message.Subject) and date_sent == date:
            mail_info = {"subject": message.Subject, "time_sent": message.SentOn.strftime("%H:%M")}
            ls.append(mail_info)

        next_message = messages.GetPrevious()
        new_date_sent = next_message.SentOn.strftime("%Y-%m-%d")
        if (re.search(filter_pattern, next_message.Subject) and new_date_sent == date):
            mail_info = {"subject": next_message.Subject, "time_sent": next_message.SentOn.strftime("%H:%M")}
            ls.append(mail_info)
        return ls
    
    def send_wfh_report(cls, subject, receivers, relevants, body):
        olItem = {
            "olMailItem": 0,
            "olAppointmentItem" : 1
        }
        send_mail = cls.outlook.CreateItem(olItem.get("olMailItem"))
        send_mail.Subject = subject
        send_mail.To = receivers
        send_mail.CC = relevants
        send_mail.Body = body
        send_mail.Display(True)

if __name__ == "__main__":
    reveivers = "hai.pham.ud@renesas.com; trung.tran.wj@renesas.com;\
                khiem.nguyen.xt@renesas.com; tung.luu.pv@renesas.com"

    # Change reporter's name
    relevants = "thinh.nguyen.zg@renesas.com; tin.tran.xw@renesas.com;\
                phuong.vo.jx@renesas.com; lam.le.yk@renesas.com;\
                long.nguyen.ak@renesas.com; thanh.ma.ra@renesas.com"

    subject = "[HSSS5][MWFH] Long Truong Report"

    current_month = datetime.datetime.today().strftime("%b")
    current_date = datetime.datetime.today().strftime("%d")
    current_time = datetime.datetime.now().strftime("%H:%M")
    today = datetime.datetime.today().strftime("%Y-%m-%d")

    outlook_handler = Outlook()
    wfh_mails = outlook_handler.get_wfh_mails(today, "WFH")
    if not wfh_mails:
        body = \
        f"""Dear Khiem-san, Hai-san, Tung-san, Trung-san
CC: HSSS5 RVC members,

[WFH - {current_month} {current_date}, 2024]

    - AM: I start WFH at {current_time}
    - PM: T.B.D

Best regards,
Long Truong.
"""
    elif len(wfh_mails) == 1:
        body = \
         f"""Dear Khiem-san, Hai-san, Tung-san, Trung-san
CC: HSSS5 RVC members,

[WFH - {current_month} {current_date}, 2024]

    - AM: I start WFH at {wfh_mails[0].get("time_sent", 0)}
    - PM: I stop WFH at {current_time}

Best regards,
Long Truong.
"""
    else:
        sys.exit("You have already sent weekly report for today")
    
    outlook_handler.send_wfh_report(subject=subject, receivers=reveivers, relevants=relevants, body=body)