import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from datetime import datetime, timedelta
import smtplib, ssl, schedule, time, os
from email.mime.multipart import MIMEMultipart
from email.mime.base import MIMEBase
from email.mime.text import MIMEText
from email import encoders
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Image 
from reportlab.lib.styles import getSampleStyleSheet 


# Generate fake sales data
def generate_fake_data(filename="sales_data.xlsx"):
    np.random.seed(42)
    n = 200  
    start_date = datetime(2024, 1, 1)

    data = {
        "Order_ID": [1000 + i for i in range(n)],
        "Order_Date": [start_date + timedelta(days=np.random.randint(0, 180)) for _ in range(n)],
        "Customer_ID": [f"C{str(np.random.randint(1, 50)).zfill(3)}" for _ in range(n)],
        "Region": np.random.choice(["North", "South", "East", "West"], n),
        "Product": np.random.choice(["Laptop", "Keyboard", "Mouse", "Headphones", "Monitor"], n),
        "Quantity": np.random.randint(1, 5, n),
        "Unit_Price": np.random.randint(20, 1500, n)
    }
    df = pd.DataFrame(data)
    df["Revenue"] = df["Quantity"] * df["Unit_Price"]
    df.to_excel(filename, index=False)
    print(f"Fake data generated: {filename}")

plt.style.use('ggplot')

# Create kpi and chart
def create_charts(filename="sales_data.xlsx"):
    df = pd.read_excel(filename)
    df["Order_Date"] = pd.to_datetime(df["Order_Date"])
    df["Month"] = df["Order_Date"].dt.to_period("M").astype(str)

    total_revenue = df["Revenue"].sum()
    total_orders = df["Order_ID"].nunique()
    avg_order_value = total_revenue / total_orders

    monthly_revenue = df.groupby("Month")["Revenue"].sum().reset_index()
    plt.figure(figsize=(6, 4))
    plt.plot(monthly_revenue["Month"], monthly_revenue["Revenue"], marker="o")
    plt.title("Monthly Revenue Trend")
    plt.xticks(rotation=45)
    plt.tight_layout()
    plt.savefig("monthly_revenue.png")
    plt.close()

    top_products = df.groupby("Product")["Revenue"].sum().reset_index().sort_values(by="Revenue", ascending=False)
    plt.figure(figsize=(6, 4))
    plt.bar(top_products["Product"], top_products["Revenue"])
    plt.title("Top Products by Revenue")
    plt.xticks(rotation=30)
    plt.tight_layout()
    plt.savefig("top_products.png")
    plt.close()

    return total_revenue, total_orders, avg_order_value


# Create pdf report
def create_pdf_report(total_revenue, total_orders, avg_order_value):
    doc = SimpleDocTemplate("Weekly_Report.pdf")
    styles = getSampleStyleSheet()
    story = []

    story.append(Paragraph("Weekly KPI Report", styles['Title']))
    story.append(Spacer(1, 12))
    story.append(Paragraph(f"Total Revenue: ${total_revenue:,.0f}", styles['Normal']))
    story.append(Paragraph(f"Total Orders: {total_orders}", styles['Normal']))
    story.append(Paragraph(f"Avg Order Value: ${avg_order_value:,.2f}", styles['Normal']))
    story.append(Spacer(1, 24))

    story.append(Paragraph("Monthly Revenue Trend", styles['Heading2']))
    story.append(Image("monthly_revenue.png", width=400, height=250))
    story.append(Spacer(1, 12))

    story.append(Paragraph("Top Products by Revenue", styles['Heading2']))
    story.append(Image("top_products.png", width=400, height=250))
    story.append(Spacer(1, 12))

    doc.build(story)
    print("Pdf report created: Weekly_Report.pdf")



total_revenue, total_orders, avg_order_value = create_charts()
create_pdf_report(total_revenue, total_orders, avg_order_value)


def send_email():
    sender_email = "kpi.report.test@gmail.com"
    receiver_email = "sepehrxm@gmail.com"
    password = "axqn dzhy xgcd vzrn"  

    msg = MIMEMultipart()
    msg["From"] = sender_email
    msg["To"] = receiver_email
    msg["Subject"] = "Weekly KPI Report"
    msg.attach(MIMEText("You can find this week report below.", "plain"))

    filename = "Weekly_Report.pdf"
    with open(filename, "rb") as attachment:
        part = MIMEBase("application", "octet-stream")
        part.set_payload(attachment.read())
    encoders.encode_base64(part)
    part.add_header("Content-Disposition", f"attachment; filename={filename}")
    msg.attach(part)

    context = ssl.create_default_context()
    with smtplib.SMTP_SSL("smtp.gmail.com", 465, context=context) as server:
        server.login(sender_email, password)
        server.sendmail(sender_email, receiver_email, msg.as_string())

    print("Email sent successfully!")


def job():
    generate_fake_data()
    total_revenue, total_orders, avg_order_value = create_charts()
    create_pdf_report(total_revenue, total_orders, avg_order_value)
    send_email()

# job()

schedule.every().wednesday.at("15:00").do(job)  

print("Scheduler started.")

while True:
    schedule.run_pending()
    time.sleep(86400)

