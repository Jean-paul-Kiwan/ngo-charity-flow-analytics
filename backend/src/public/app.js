async function fetchJSON(url, options) {
  const res = await fetch(url, options);
  const text = await res.text();
  let data;
  try { data = JSON.parse(text); } catch { data = text; }
  if (!res.ok) throw new Error((data && data.error) || res.statusText);
  return data;
}

function money(n) {
  const num = Number(n || 0);
  return num.toLocaleString(undefined, { minimumFractionDigits: 0 });
}

// DASHBOARD
async function loadDashboard() {
  const donationCountEl = document.getElementById("donationCount");
  const donationTotalEl = document.getElementById("donationTotal");
  const ngoCountEl = document.getElementById("ngoCount");
  const tbody = document.querySelector("#donationsTable tbody");
  const createForm = document.getElementById("donationCreateForm");
  const resetCreateBtn = document.getElementById("donationCreateReset");
  const ngoSelect = document.getElementById("ngoSelect");


  if (!donationCountEl || !donationTotalEl || !ngoCountEl || !tbody) return;

  const [ngos, donations] = await Promise.all([
    fetchJSON("/ngos"),
    fetchJSON("/donations/populated/all")
  ]);

  ngoCountEl.textContent = ngos.length;

  donationCountEl.textContent = donations.length;
  const total = donations.reduce((sum, d) => sum + (d.amount || 0), 0);
  donationTotalEl.textContent = money(total);

  tbody.innerHTML = "";
  donations.slice(0, 10).forEach(d => {
    const tr = document.createElement("tr");
    const date = d.donationDate ? new Date(d.donationDate).toISOString().slice(0,10) : "";
    const ngoName = d.ngoId?.name || "";
    tr.innerHTML = `
      <td>${date}</td>
      <td>${d.donorName || ""}</td>
      <td>${money(d.amount)} ${d.currency || ""}</td>
      <td>${d.method || ""}</td>
      <td>${d.status || ""}</td>
      <td>${ngoName}</td>
    `;
    tbody.appendChild(tr);
  });
}

// NGOS PAGE
async function loadNGOs() {
  const tableBody = document.querySelector("#ngosTable tbody");
  const form = document.getElementById("ngoForm");
  const filterForm = document.getElementById("ngoFilterForm");
  const clearBtn = document.getElementById("ngoClearBtn");

  // Modal elements
  const modal = document.getElementById("ngoModal");
  const closeBtn = document.getElementById("closeNgoModal");
  const cancelBtn = document.getElementById("cancelNgoEdit");
  const editForm = document.getElementById("ngoEditForm");

  if (!tableBody || !form) return;

  function openModal() { modal?.classList.remove("hidden"); }
  function closeModal() { modal?.classList.add("hidden"); }

  closeBtn?.addEventListener("click", closeModal);
  cancelBtn?.addEventListener("click", closeModal);

  modal?.addEventListener("click", (e) => {
    if (e.target === modal) closeModal();
  });

  function buildNgoUrlFromForm() {
    const url = new URL("/ngos", window.location.origin);
    if (!filterForm) return url.pathname;

    const fd = new FormData(filterForm);
    ["search", "country", "category", "verified"].forEach((k) => {
      const v = (fd.get(k) || "").toString().trim();
      if (v) url.searchParams.set(k, v);
    });

    return url.pathname + url.search;
  }

  async function refresh() {
    const ngos = await fetchJSON(buildNgoUrlFromForm());
    tableBody.innerHTML = "";

    ngos.forEach((n) => {
      const tr = document.createElement("tr");
      tr.innerHTML = `
        <td>${n.name || ""}</td>
        <td>${n.country || ""}</td>
        <td>${n.category || ""}</td>
        <td>${n.isVerified ? "yes" : "no"}</td>
        <td class="actions">
          <button 
            data-action="edit" 
            data-id="${n._id}"
            data-name="${n.name || ""}"
            data-country="${n.country || ""}"
            data-category="${n.category || ""}"
            data-verified="${n.isVerified ? "true" : "false"}"
            data-tags="${(n.tags || []).join(",")}"
            data-email="${n.contact?.email || ""}"
          >Edit</button>
          <button data-action="delete" data-id="${n._id}">Delete</button>
        </td>
      `;
      tableBody.appendChild(tr);
    });
  }

  // Create NGO
  form.addEventListener("submit", async (e) => {
    e.preventDefault();
    const fd = new FormData(form);

    const payload = {
      name: fd.get("name"),
      country: fd.get("country"),
      category: fd.get("category"),
      isVerified: true,
      foundedAt: new Date().toISOString(),
      tags: ["web-ui"],
      contact: { email: "web@ngo.org", phone: "+96170000000", address: "Beirut" },
    };

    try {
      await fetchJSON("/ngos", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(payload),
      });
      form.reset();
      await refresh();
      alert("✅ NGO created!");
    } catch (err) {
      alert("❌ " + err.message);
    }
  });

  // Apply filters
  filterForm?.addEventListener("submit", async (e) => {
    e.preventDefault();
    await refresh();
  });

  // Clear filters
  clearBtn?.addEventListener("click", async () => {
    filterForm?.reset();
    await refresh();
  });

  // Table actions
  tableBody.addEventListener("click", async (e) => {
    const btn = e.target.closest("button");
    if (!btn) return;

    const action = btn.getAttribute("data-action");
    const id = btn.getAttribute("data-id");
    if (!id) return;

    if (action === "delete") {
      if (!confirm("Delete this NGO?")) return;
      try {
        await fetchJSON(`/ngos/${id}`, { method: "DELETE" });
        await refresh();
        alert("✅ Deleted");
      } catch (err) {
        alert("❌ " + err.message);
      }
    }

    if (action === "edit") {
      if (!editForm || !modal) {
        alert("❌ NGO modal not found. Add NGO modal HTML in ngos.ejs");
        return;
      }

      editForm.elements["id"].value = id;
      editForm.elements["name"].value = btn.getAttribute("data-name") || "";
      editForm.elements["country"].value = btn.getAttribute("data-country") || "";
      editForm.elements["category"].value = btn.getAttribute("data-category") || "";
      editForm.elements["isVerified"].value = btn.getAttribute("data-verified") || "false";
      editForm.elements["tags"].value = btn.getAttribute("data-tags") || "";
      editForm.elements["email"].value = btn.getAttribute("data-email") || "";

      openModal();
    }
  });

  // Save modal changes
  editForm?.addEventListener("submit", async (e) => {
    e.preventDefault();

    const id = editForm.elements["id"].value;

    const name = editForm.elements["name"].value.trim();
    const country = editForm.elements["country"].value.trim();
    const category = editForm.elements["category"].value;
    const isVerified = editForm.elements["isVerified"].value === "true";
    const tags = (editForm.elements["tags"].value || "")
      .split(",").map(s => s.trim()).filter(Boolean);
    const email = editForm.elements["email"].value.trim();

    const payload = {};
    if (name) payload.name = name;
    if (country) payload.country = country;
    if (category) payload.category = category;
    payload.isVerified = isVerified;
    if (tags.length) payload.tags = tags;
    if (email) payload.contact = { email };

    try {
      await fetchJSON(`/ngos/${id}`, {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(payload),
      });

      closeModal();
      await refresh();
      alert("✅ NGO updated");
    } catch (err) {
      alert("❌ " + err.message);
    }
  });

  await refresh();
}

// DONATIONS PAGE
async function loadDonationsUI() {
  const tbody = document.querySelector("#donationsTableFull tbody");
  const filterForm = document.getElementById("donationFilterForm");
  const clearBtn = document.getElementById("donationClearBtn");
  const errorBox = document.getElementById("donationsError");

  // Create modal elements
  const createModal = document.getElementById("donationCreateModal");
  const openCreateBtn = document.getElementById("openCreateDonation");
  const closeCreateBtn = document.getElementById("closeCreateDonation");
  const createForm = document.getElementById("donationCreateForm");
  const resetCreateBtn = document.getElementById("donationCreateReset");
  const ngoSelect = document.getElementById("ngoSelect");

  // Edit modal elements
  const modal = document.getElementById("donationModal");
  const closeBtn = document.getElementById("closeDonationModal");
  const cancelBtn = document.getElementById("cancelDonationEdit");
  const editForm = document.getElementById("donationEditForm");

  if (!tbody || !filterForm) return;

  function showError(msg) {
    if (!errorBox) return;
    errorBox.style.display = "block";
    errorBox.textContent = msg;
  }
  function clearError() {
    if (!errorBox) return;
    errorBox.style.display = "none";
    errorBox.textContent = "";
  }

  function openModal(el) { el?.classList.remove("hidden"); }
  function closeModal(el) { el?.classList.add("hidden"); }

  // Modal close handlers
  closeBtn?.addEventListener("click", () => closeModal(modal));
  cancelBtn?.addEventListener("click", () => closeModal(modal));
  modal?.addEventListener("click", (e) => { if (e.target === modal) closeModal(modal); });

  closeCreateBtn?.addEventListener("click", () => closeModal(createModal));
  createModal?.addEventListener("click", (e) => { if (e.target === createModal) closeModal(createModal); });

  openCreateBtn?.addEventListener("click", async () => {
    // ensure dropdown loaded when opening
    try {
      await loadNgoDropdown();
      openModal(createModal);
    } catch (e) {
      alert("❌ Failed to load NGOs for dropdown: " + e.message);
    }
  });

  function buildUrl() {
    const url = new URL("/donations", window.location.origin);
    const fd = new FormData(filterForm);

    ["ngoId", "status", "method", "minAmount", "maxAmount", "recurring", "tag"].forEach(k => {
      const v = (fd.get(k) || "").toString().trim();
      if (v) url.searchParams.set(k, v);
    });

    return url.pathname + url.search;
  }

  async function loadNgoDropdown() {
    if (!ngoSelect) return;

    const ngos = await fetchJSON("/ngos");
    ngoSelect.innerHTML = `<option value="">Select NGO...</option>`;

    ngos.forEach(n => {
      const opt = document.createElement("option");
      opt.value = n._id;
      opt.textContent = `${n.name} (${n.country})`;
      ngoSelect.appendChild(opt);
    });
  }

  async function refresh() {
    clearError();
    try {
      // get filtered donations
      const donations = await fetchJSON(buildUrl());

      // get ngos for mapping names
      const ngos = await fetchJSON("/ngos");
      const ngoMap = new Map(ngos.map(n => [n._id, n]));

      tbody.innerHTML = "";
      donations.forEach(d => {
        const tr = document.createElement("tr");
        const date = d.donationDate ? new Date(d.donationDate).toISOString().slice(0,10) : "";
        const ngo = ngoMap.get(d.ngoId) || {};
        tr.innerHTML = `
          <td>${date}</td>
          <td>${d.donorName || ""}</td>
          <td>${d.donorEmail || ""}</td>
          <td>${(d.amount ?? 0)} ${d.currency || ""}</td>
          <td>${d.method || ""}</td>
          <td><span class="badge ${d.status === "completed" ? "ok" : (d.status==="pending" ? "warn":"danger")}">${d.status || ""}</span></td>
          <td>${d.isRecurring ? "Yes" : "No"}</td>
          <td>${ngo.name || ""}</td>
          <td class="actions">
            <button 
              data-action="edit-donation" 
              data-id="${d._id}"
              data-status="${d.status || "completed"}"
              data-amount="${d.amount ?? 1}"
              data-method="${d.method || "cash"}"
              data-recurring="${d.isRecurring ? "true" : "false"}"
              data-tags="${(d.tags || []).join(",")}"
              data-metanote="${d.meta?.note || ""}"
            >Edit</button>
            <button data-action="delete-donation" data-id="${d._id}">Delete</button>
          </td>
        `;
        tbody.appendChild(tr);
      });
    } catch (err) {
      // If anything fails, show error instead of blank table
      showError("Failed to load donations: " + err.message);
      tbody.innerHTML = "";
    }
  }

  // Filters
  filterForm.addEventListener("submit", async (e) => {
    e.preventDefault();
    await refresh();
  });

  clearBtn?.addEventListener("click", async () => {
    filterForm.reset();
    await refresh();
  });

  // Create donation
  createForm?.addEventListener("submit", async (e) => {
    e.preventDefault();
    const fd = new FormData(createForm);

    const payload = {
      donorName: (fd.get("donorName") || "").toString(),
      donorEmail: (fd.get("donorEmail") || "").toString(),
      amount: Number(fd.get("amount")),
      currency: fd.get("currency"),
      method: fd.get("method"),
      status: fd.get("status"),
      isRecurring: fd.get("isRecurring") === "true",
      donationDate: new Date().toISOString(),
      tags: (fd.get("tags") || "").toString().split(",").map(s => s.trim()).filter(Boolean),
      meta: {
        source: (fd.get("metaSource") || "").toString(),
        platform: (fd.get("metaPlatform") || "").toString(),
        note: (fd.get("metaNote") || "").toString(),
      },
      ngoId: fd.get("ngoId")
    };

    try {
      await fetchJSON("/donations", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(payload)
      });

      createForm.reset();
      closeModal(createModal);
      await refresh();
      alert("✅ Donation created (saved in MongoDB)");
    } catch (err) {
      alert("❌ " + err.message);
    }
  });

  resetCreateBtn?.addEventListener("click", () => createForm?.reset());

  // Table actions
  tbody.addEventListener("click", async (e) => {
    const btn = e.target.closest("button");
    if (!btn) return;

    const action = btn.getAttribute("data-action");
    const id = btn.getAttribute("data-id");

    if (action === "delete-donation") {
      if (!confirm("Delete this donation?")) return;
      try {
        await fetchJSON(`/donations/${id}`, { method: "DELETE" });
        await refresh();
        alert("✅ Donation deleted");
      } catch (err) {
        alert("❌ " + err.message);
      }
    }

    if (action === "edit-donation") {
      if (!editForm || !modal) {
        alert("❌ Edit modal not found (donationModal).");
        return;
      }

      editForm.elements["id"].value = id;
      editForm.elements["status"].value = btn.getAttribute("data-status") || "completed";
      editForm.elements["amount"].value = btn.getAttribute("data-amount") || "1";
      editForm.elements["method"].value = btn.getAttribute("data-method") || "cash";
      editForm.elements["isRecurring"].value = btn.getAttribute("data-recurring") || "false";
      editForm.elements["tags"].value = btn.getAttribute("data-tags") || "";
      editForm.elements["metaNote"].value = btn.getAttribute("data-metanote") || "";

      openModal(modal);
    }
  });

  // Save edit changes
  editForm?.addEventListener("submit", async (e) => {
    e.preventDefault();

    const id = editForm.elements["id"].value;

    const payload = {
      status: editForm.elements["status"].value,
      amount: Number(editForm.elements["amount"].value),
      method: editForm.elements["method"].value,
      isRecurring: editForm.elements["isRecurring"].value === "true",
      tags: (editForm.elements["tags"].value || "")
        .split(",")
        .map(s => s.trim())
        .filter(Boolean),
      meta: { note: editForm.elements["metaNote"].value || "" }
    };

    try {
      await fetchJSON(`/donations/${id}`, {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(payload),
      });

      closeModal(modal);
      await refresh();
      alert("✅ Donation updated");
    } catch (err) {
      alert("❌ " + err.message);
    }
  });

  // initial load
  await refresh();
}

// Run correct loader based on page
loadDashboard();
loadNGOs();
loadDonationsUI();
