<h1 align="center">☁️ Cloudana CostInsight</h1>

<p align="center">
  <img src="https://img.shields.io/badge/HTML5-E34F26?style=for-the-badge&logo=html5&logoColor=white" />
  <img src="https://img.shields.io/badge/CSS3-1572B6?style=for-the-badge&logo=css3&logoColor=white" />
  <img src="https://img.shields.io/badge/JavaScript-F7DF1E?style=for-the-badge&logo=javascript&logoColor=black" />
  <img src="https://img.shields.io/badge/Node.js-339933?style=for-the-badge&logo=nodedotjs&logoColor=white" />
  <img src="https://img.shields.io/badge/AWS%20Lambda-FF9900?style=for-the-badge&logo=awslambda&logoColor=white" />
  <img src="https://img.shields.io/badge/Amazon%20CloudWatch-FF4F8B?style=for-the-badge&logo=amazoncloudwatch&logoColor=white" />
  <img src="https://img.shields.io/badge/MongoDB-47A248?style=for-the-badge&logo=mongodb&logoColor=white" />
</p>

---

**CostInsight** is a web app to **monitor and optimize cloud costs**.
It uses **Node.js, Express, HTML, JS, MongoDB, and AWS services**.
Features include real-time cost tracking, risk alerts, optimization advice, statistical charts, and a **chatbot** for user help.

The app also uses **AWS Lambda** to fetch CloudWatch metrics and automatically shut down instances when limits are reached.

**Deployed on Vercel:** https://your-vercel-link.vercel.app

---

## Project Structure

```
MiniProject-Cloud/
│
├─ backend/
│   ├─ middleware/       # Authentication
│   ├─ models/           # MongoDB models (User, CloudHistory)
│   ├─ routes/           # Express routes
│   ├─ services/         # AWS and cost analysis functions
│   └─ server.js         # Server setup
│
├─ frontend/
│   ├─ css/              # Styles
│   ├─ pages/            # HTML pages
│   └─ scripts/          # JS for auth, dashboard, signup
│
├─ lambda/
│   ├─ cloudwatch-fetcher.js       # Fetch CloudWatch metrics
│   └─ instance-auto-shutdown.js   # Auto shutdown instances
│
├─ .env                    # Environment variables
├─ package.json
└─ package-lock.json
```

---

## Features

* **AWS Lambda Functions**:

  * Fetch CloudWatch metrics for cost tracking
  * Auto shutdown instances based on limits
* **Web App**:

  * Dashboard for live monitoring and cost stats
  * High-cost service alerts
  * Optimization advice
  * Statistical charts
  * Chatbot for user support
* **Backend & Database**:

  * Node.js + Express
  * MongoDB for user data and cloud history
  * Gemini API integration

---

## Setup Instructions

1. **Clone the project**:

```bash
git clone https://github.com/ananyagla/Mini-Project_2025
cd MiniProject-Cloud
```

2. **Install dependencies**:

```bash
npm install
```

3. **Set environment variables** in `.env`:

```
API_ENDPOINT=<Your Backend API URL>
API_KEY=<Your Auth Key>
MONGO_URI=<Your MongoDB URI>
```

4. **Run locally**:

```bash
npm start
```

5. **Open in browser**:

```
http://localhost:3000
```

---

## Usage

* Sign up or log in
* Check the dashboard for live stats
* Get cost alerts and optimization advice
* Use chatbot for help
* Lambda functions handle automatic metric fetching and instance shutdown

---

## Technologies Used

* **Frontend:** HTML, CSS, JS
* **Backend:** Node.js, Express.js
* **Database:** MongoDB
* **Cloud Services:** AWS Lambda, CloudWatch, EC2
* **API:** Gemini API

---

## Contribution

Contributions welcome. Open an issue or pull request.

---

## License

©CostInsight - 2025

---
