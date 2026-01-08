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
 * ✅ LIST Donations + FILTERS
 * GET /donations
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

    if (minAmount || maxAmount) {
      filter.amount = {};
      if (minAmount) filter.amount.$gte = Number(minAmount);
      if (maxAmount) filter.amount.$lte = Number(maxAmount);
    }

    if (recurring !== undefined && recurring !== "") {
      filter.isRecurring = recurring === "true";
    }

    if (tag) {
      filter.tags = { $in: [tag] };
    }

    if (startDate || endDate) {
      filter.donationDate = {};
      if (startDate) filter.donationDate.$gte = new Date(startDate);
      if (endDate) filter.donationDate.$lte = new Date(endDate);
    }

    const pageNum = Math.max(parseInt(page || "1", 10), 1);
    const limitNum = Math.min(Math.max(parseInt(limit || "50", 10), 1), 200);
    const sortField = (sort || "donationDate").toString();
    const sortOrder = (order || "desc").toLowerCase() === "asc" ? 1 : -1;
    const skip = (pageNum - 1) * limitNum;

    const items = await Donation.find(filter)
      .sort({ [sortField]: sortOrder })
      .skip(skip)
      .limit(limitNum);

    return res.json(items);
  } catch (e) {
    return res.status(400).json({ error: e.message });
  }
});

/**
 * ✅ POPULATE
 * GET /donations/populated/all
 */
router.get("/populated/all", async (req, res) => {
  try {
    const data = await Donation.find()
      .populate("ngoId", "name country category isVerified")
      .sort({ donationDate: -1 });

    return res.json(data);
  } catch {
    return res.status(500).json({ error: "Failed to fetch populated donations" });
  }
});

/**
 * ✅ AGGREGATE JOIN
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
  } catch {
    return res.status(500).json({ error: "Failed to aggregate join donations" });
  }
});

/**
 * ✅ EXPORT CSV
 * GET /donations/export/csv
 */
router.get("/export/csv", async (req, res) => {
  try {
    const donations = await Donation.find()
      .populate("ngoId", "name")
      .sort({ donationDate: -1 })
      .lean();

    const headers = [
      "donationDate",
      "donorName",
      "donorEmail",
      "amount",
      "currency",
      "method",
      "status",
      "isRecurring",
      "ngoName",
    ];

    const escapeCsv = (v) => {
      if (v === null || v === undefined) return '""';
      return `"${String(v).replace(/"/g, '""')}"`;
    };

    const lines = [
      headers.join(","),
      ...donations.map(d =>
        headers.map(h => {
          if (h === "ngoName") return escapeCsv(d.ngoId?.name || "");
          return escapeCsv(d[h]);
        }).join(",")
      ),
    ];

    res.setHeader("Content-Type", "text/csv; charset=utf-8");
    res.setHeader("Content-Disposition", "attachment; filename=donations.csv");
    return res.send(lines.join("\n"));
  } catch (err) {
    console.error("CSV export error:", err);
    return res.status(500).json({ error: "CSV export failed" });
  }
});

/**
 * ✅ ANALYTICS BY NGO (completed only)
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
          ngoName: "$ngo.name",
        },
      },
      { $sort: { totalAmount: -1 } },
    ]);

    return res.json(data);
  } catch {
    return res.status(500).json({ error: "Failed to compute analytics" });
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
  } catch {
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
  } catch {
    return res.status(400).json({ error: "Invalid id" });
  }
});

module.exports = router;
