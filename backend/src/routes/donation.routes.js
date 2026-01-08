const express = require("express");
const Donation = require("../models/Donation");

const router = express.Router();

/**
 * ✅ CREATE Donation
 * POST /donations
 */
router.post("/", async (req, res) => {
  try {
    const donation = await Donation.create(req.body);
    return res.status(201).json(donation);
  } catch (e) {
    return res.status(400).json({ error: e.message });
  }
});

/**
 * ✅ LIST Donations + FILTERS (+ optional pagination/sort)
 * GET /donations?ngoId=...&method=card&status=completed&minAmount=50&maxAmount=500&tag=education&startDate=2026-01-01&endDate=2026-02-01&recurring=true
 *
 * Optional:
 *  - page=1
 *  - limit=50
 *  - sort=donationDate (or amount, createdAt, etc)
 *  - order=desc|asc
 */
router.get("/", async (req, res) => {
  try {
    const {
      ngoId,
      method,
      status,
      minAmount,
      maxAmount,
      recurring,
      tag,
      startDate,
      endDate,
      page,
      limit,
      sort,
      order,
    } = req.query;

    const filter = {};

    if (ngoId) filter.ngoId = ngoId;
    if (method) filter.method = method;
    if (status) filter.status = status;

    // Amount range
    if (minAmount || maxAmount) {
      filter.amount = {};
      if (minAmount) filter.amount.$gte = Number(minAmount);
      if (maxAmount) filter.amount.$lte = Number(maxAmount);
    }

    // Recurring (avoid filtering when empty)
    if (recurring !== undefined && recurring !== "") {
      filter.isRecurring = recurring === "true";
    }

    // Tags array contains a value
    if (tag) {
      filter.tags = { $in: [tag] };
    }

    // Date range
    if (startDate || endDate) {
      filter.donationDate = {};
      if (startDate) filter.donationDate.$gte = new Date(startDate);
      if (endDate) filter.donationDate.$lte = new Date(endDate);
    }

    // ✅ Pagination + sort (Step 3)
    const pageNum = Math.max(parseInt(page || "1", 10), 1);
    const limitNum = Math.min(Math.max(parseInt(limit || "50", 10), 1), 200);
    const sortField = (sort || "donationDate").toString();
    const sortOrder = (order || "desc").toString().toLowerCase() === "asc" ? 1 : -1;
    const skip = (pageNum - 1) * limitNum;

    const [items, total] = await Promise.all([
      Donation.find(filter).sort({ [sortField]: sortOrder }).skip(skip).limit(limitNum),
      Donation.countDocuments(filter),
    ]);

    // If frontend expects array only, you can return items.
    // But API is more professional with metadata:
    return res.json(items);

  } catch (e) {
    return res.status(400).json({ error: e.message });
  }
});

/**
 * ✅ POPULATE (advanced)
 * GET /donations/populated/all
 */
router.get("/populated/all", async (req, res) => {
  try {
    const data = await Donation.find()
      .populate("ngoId", "name country category isVerified")
      .sort({ donationDate: -1 });

    return res.json(data);
  } catch (e) {
    return res.status(500).json({ error: "Failed to fetch populated donations" });
  }
});

/**
 * ✅ AGGREGATE JOIN (advanced)
 * GET /donations/aggregate/join
 */
router.get("/aggregate/join", async (req, res) => {
  try {
    const data = await Donation.aggregate([
      {
        $lookup: {
          from: "ngos",
          localField: "ngoId",
          foreignField: "_id",
          as: "ngo",
        },
      },
      { $unwind: "$ngo" },
      {
        $project: {
          donorName: 1,
          donorEmail: 1,
          amount: 1,
          method: 1,
          status: 1,
          donationDate: 1,
          isRecurring: 1,
          tags: 1,
          meta: 1,
          allocation: 1,
          ngo: { name: 1, country: 1, category: 1, isVerified: 1 },
        },
      },
      { $sort: { donationDate: -1 } },
    ]);

    return res.json(data);
  } catch (e) {
    return res.status(500).json({ error: "Failed to aggregate join donations" });
  }
});

/**
 * ✅ ANALYTICS: total amount per NGO (completed only)
 * GET /donations/analytics/by-ngo
 */
router.get("/analytics/by-ngo", async (req, res) => {
  try {
    const data = await Donation.aggregate([
      { $match: { status: "completed" } },
      {
        $group: {
          _id: "$ngoId",
          totalAmount: { $sum: "$amount" },
          count: { $sum: 1 },
        },
      },
      {
        $lookup: {
          from: "ngos",
          localField: "_id",
          foreignField: "_id",
          as: "ngo",
        },
      },
      { $unwind: "$ngo" },
      {
        $project: {
          ngoId: "$_id",
          totalAmount: 1,
          count: 1,
          ngo: { name: 1, country: 1, category: 1 },
        },
      },
      { $sort: { totalAmount: -1 } },
    ]);

    return res.json(data);
  } catch (e) {
    return res.status(500).json({ error: "Failed to compute analytics" });
  }
});

/**
 * ✅ ANALYTICS: totals by method (completed only)
 * GET /donations/analytics/by-method
 */
router.get("/analytics/by-method", async (req, res) => {
  try {
    const data = await Donation.aggregate([
      { $match: { status: "completed" } },
      {
        $group: {
          _id: "$method",
          totalAmount: { $sum: "$amount" },
          count: { $sum: 1 },
        },
      },
      { $sort: { totalAmount: -1 } },
    ]);
    return res.json(data);
  } catch (e) {
    return res.status(500).json({ error: "Failed to compute analytics by method" });
  }
});

/**
 * ✅ ANALYTICS: daily totals (completed)
 * GET /donations/analytics/daily?startDate=YYYY-MM-DD&endDate=YYYY-MM-DD
 */
router.get("/analytics/daily", async (req, res) => {
  try {
    const { startDate, endDate } = req.query;

    const match = { status: "completed" };
    if (startDate || endDate) {
      match.donationDate = {};
      if (startDate) match.donationDate.$gte = new Date(startDate);
      if (endDate) match.donationDate.$lte = new Date(endDate);
    }

    const data = await Donation.aggregate([
      { $match: match },
      {
        $group: {
          _id: {
            $dateToString: { format: "%Y-%m-%d", date: "$donationDate" },
          },
          totalAmount: { $sum: "$amount" },
          count: { $sum: 1 },
        },
      },
      { $sort: { _id: 1 } },
    ]);

    return res.json(data);
  } catch (e) {
    return res.status(500).json({ error: "Failed to compute daily analytics" });
  }
});

/**
 * ✅ GET Donation by id
 * GET /donations/:id
 */
router.get("/:id", async (req, res) => {
  try {
    const donation = await Donation.findById(req.params.id);
    if (!donation) return res.status(404).json({ error: "Donation not found" });
    return res.json(donation);
  } catch (e) {
    return res.status(400).json({ error: "Invalid id" });
  }
});

/**
 * ✅ UPDATE Donation
 * PUT /donations/:id
 */
router.put("/:id", async (req, res) => {
  try {
    const updated = await Donation.findByIdAndUpdate(req.params.id, req.body, {
      new: true,
      runValidators: true,
    });
    if (!updated) return res.status(404).json({ error: "Donation not found" });
    return res.json(updated);
  } catch (e) {
    return res.status(400).json({ error: e.message });
  }
});

/**
 * ✅ DELETE Donation
 * DELETE /donations/:id
 */
router.delete("/:id", async (req, res) => {
  try {
    const deleted = await Donation.findByIdAndDelete(req.params.id);
    if (!deleted) return res.status(404).json({ error: "Donation not found" });
    return res.json({ ok: true });
  } catch (e) {
    return res.status(400).json({ error: "Invalid id" });
  }
});

module.exports = router;
