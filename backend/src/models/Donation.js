const mongoose = require("mongoose");

const donationSchema = new mongoose.Schema(
  {
    donorName: { type: String, required: true, lowercase: true, trim: true },

    method: {
      type: String,
      required: true,
      enum: ["cash", "card", "bank_transfer", "crypto"],
    },

    // ✅ Amount between 1 and 100,000 (for ALL methods)
    amount: { type: Number, required: true, min: 1, max: 100000 },

    donationDate: { type: Date, required: true },

    isRecurring: { type: Boolean, default: false },

    tags: { type: [String], default: [] },

    receiptUrls: { type: [String], default: [] },

    meta: {
      source: { type: String, default: "" },
      platform: { type: String, default: "" },
      note: { type: String, default: "" },
    },

    donorEmail: {
      type: String,
      required: true,
      trim: true,
      validate: {
        validator: (v) => /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(v),
        message: "Invalid email format",
      },
    },

    ngoId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "NGO",
      required: true,
    },

    status: {
      type: String,
      enum: ["pending", "completed", "failed", "refunded"],
      default: "completed",
    },

    currency: {
      type: String,
      enum: ["USD", "EUR", "LBP"],
      default: "USD",
    },

    allocation: {
      type: [
        {
          label: { type: String, required: true },
          percent: { type: Number, required: true, min: 0, max: 100 },
        },
      ],
      default: [],
    },
  },
  { timestamps: true }
);

// ✅ Business rules (clean, consistent)
donationSchema.pre("validate", function () {
  // 1) Donation date cannot be in the future
  if (this.donationDate && this.donationDate > new Date()) {
    this.invalidate("donationDate", "Donation date cannot be in the future");
  }

  // 2) Crypto donations must include meta.source
  if (this.method === "crypto") {
    if (!this.meta?.source || this.meta.source.trim().length < 2) {
      this.invalidate("meta.source", "Crypto donations require meta.source");
    }
  }

  // 3) Refunded donations must have a reason
  if (this.status === "refunded") {
    if (!this.meta?.note || this.meta.note.trim().length < 5) {
      this.invalidate("meta.note", "Refunded donations require a reason");
    }
  }

  // 4) Allocation percent sum ≤ 100
  if (Array.isArray(this.allocation)) {
    const sum = this.allocation.reduce((s, a) => s + Number(a.percent || 0), 0);
    if (sum > 100) {
      this.invalidate("allocation", "Allocation percent sum cannot exceed 100");
    }
  }
});

module.exports = mongoose.model("Donation", donationSchema);
