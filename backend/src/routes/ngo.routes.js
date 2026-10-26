const express = require("express");
const NGO = require("../models/NGO");

const router = express.Router();

// CREATE NGO
router.post("/", async (req, res) => {
  try {
    const ngo = await NGO.create(req.body);
    return res.status(201).json(ngo);
  } catch (e) {
    return res.status(400).json({ error: e.message });
  }
});

// LIST NGOs + FILTERS
// /ngos?country=Lebanon&category=health&verified=true&tag=medical&search=hope
router.get("/", async (req, res) => {
  try {
    const { country, category, verified, tag, foundedAfter, search } = req.query;

    const filter = {};

    // ✅ country case-insensitive exact match
    if (country) filter.country = new RegExp(`^${country}$`, "i");

    if (category) filter.category = category;

    // ✅ avoid filtering when verified=""
    if (verified !== undefined && verified !== "") {
      filter.isVerified = verified === "true";
    }

    // ✅ tags is an array
    if (tag) filter.tags = { $in: [tag] };

    if (foundedAfter) filter.foundedAt = { $gte: new Date(foundedAfter) };

    if (search) {
      filter.name = { $regex: search, $options: "i" };
    }

    const ngos = await NGO.find(filter).sort({ createdAt: -1 });
    return res.json(ngos);
  } catch (e) {
    return res.status(500).json({ error: "Failed to fetch NGOs" });
  }
});

// GET NGO by id
router.get("/:id", async (req, res) => {
  try {
    const ngo = await NGO.findById(req.params.id);
    if (!ngo) return res.status(404).json({ error: "NGO not found" });
    return res.json(ngo);
  } catch {
    return res.status(400).json({ error: "Invalid id" });
  }
});

// UPDATE NGO (edit)
router.put("/:id", async (req, res) => {
  try {
    const updated = await NGO.findByIdAndUpdate(req.params.id, req.body, {
      new: true,
      runValidators: true,
    });
    if (!updated) return res.status(404).json({ error: "NGO not found" });
    return res.json(updated);
  } catch (e) {
    return res.status(400).json({ error: e.message });
  }
});

// DELETE NGO
router.delete("/:id", async (req, res) => {
  try {
    const deleted = await NGO.findByIdAndDelete(req.params.id);
    if (!deleted) return res.status(404).json({ error: "NGO not found" });
    return res.json({ ok: true });
  } catch {
    return res.status(400).json({ error: "Invalid id" });
  }
});

module.exports = router;
