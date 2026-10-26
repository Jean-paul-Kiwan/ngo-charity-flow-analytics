require("dotenv").config();
const path = require("path");
const express = require("express");
const cors = require("cors");

const connectDB = require("./config/db");

const ngoRoutes = require("./routes/ngo.routes");
const donationRoutes = require("./routes/donation.routes");

const app = express();

// API middlewares
app.use(cors());
app.use(express.json());

// ✅ Static files (CSS/JS)
app.use("/public", express.static(path.join(__dirname, "public")));

// ✅ Views (EJS)
app.set("view engine", "ejs");
app.set("views", path.join(__dirname, "views"));

// ✅ Health check API
app.get("/api", (req, res) => {
  res.json({ status: "ok", service: "NGO Charity Flow Analytics API" });
});

// ✅ Your existing API routes
app.use("/ngos", ngoRoutes);
app.use("/donations", donationRoutes);

app.get("/health", (req, res) => res.json({ ok: true, time: new Date() }));


// ✅ Frontend pages (server-rendered)
app.get("/", (req, res) => res.redirect("/dashboard"));

app.get("/dashboard", (req, res) => {
  res.render("layout", {
  title: "Dashboard",
  body: require("fs").readFileSync(path.join(__dirname, "views", "dashboard.ejs"), "utf8")
});
});

app.get("/ui/ngos", (req, res) => {
 res.render("layout", {
  title: "NGOs",
  body: require("fs").readFileSync(path.join(__dirname, "views", "ngos.ejs"), "utf8")
});
});

app.get("/ui/donations", (req, res) => {
  res.render("layout", {
    title: "Donations",
    body: require("fs").readFileSync(path.join(__dirname, "views", "donations.ejs"), "utf8")
  });
});

app.get("/ui/analytics", (req, res) => {
  res.render("layout", {
    title: "Analytics",
    body: require("fs").readFileSync(path.join(__dirname, "views", "analytics.ejs"), "utf8")
  });
});



const PORT = process.env.PORT || 3000;

connectDB(process.env.MONGO_URI)
  .then(() => {
    app.listen(PORT, () => {
      console.log(`🚀 Server running on http://localhost:${PORT}`);
      console.log(`🌐 UI: http://localhost:${PORT}/dashboard`);
    });
  })
  .catch((err) => {
    console.error("❌ MongoDB connection failed:", err.message);
    process.exit(1);
  });
