const mongoose = require("mongoose");

const ngoSchema = new mongoose.Schema(
  {
    // ✅ String constraint (choose lowercase)
    name: { type: String, required: true, trim: true, lowercase: true },

    country: { type: String, required: true, trim: true },

    // ✅ enum constraint
    category: {
      type: String,
      enum: ["health", "education", "food", "shelter", "environment", "emergency"],
      required: true,
    },

    isVerified: { type: Boolean, default: false },

    foundedAt: { type: Date },

    tags: { type: [String], default: [] },

    // ✅ JSON-like fields
    contact: {
      email: { type: String, default: "", trim: true },
      phone: { type: String, default: "", trim: true },
      address: { type: String, default: "", trim: true },
    },

    // extras (you already had similar)
    socialLinks: {
      website: { type: String, default: "" },
      facebook: { type: String, default: "" },
      instagram: { type: String, default: "" },
    },

    metrics: {
      totalBeneficiaries: { type: Number, default: 0, min: 0 },
      rating: { type: Number, default: 0, min: 0, max: 5 },
    },

    programs: { type: [String], default: [] },
    serviceAreas: { type: [String], default: [] },
  },
  { timestamps: true }
);

// ✅ Business rule: verified NGO must have a valid email
ngoSchema.pre("validate", function () {
  if (this.isVerified) {
    const email = this.contact?.email;
    const ok = email && /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(String(email).trim());
    if (!ok) {
      this.invalidate("contact.email", "Verified NGOs must have a valid contact.email");
    }
  }
});

module.exports = mongoose.model("NGO", ngoSchema);
