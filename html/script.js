// R4X Outfit Bag by R4X Labs

let outfits = [];
let maxOutfits = 5;
let selectedSlot = null;
let deleteIndex = null;

// DOM Elements
const container = document.getElementById('outfit-bag');
const notificationsContainer = document.getElementById('notifications-container');
const outfitList = document.getElementById('outfit-list');
const outfitNameInput = document.getElementById('outfit-name');
const saveBtn = document.getElementById('save-btn');
const closeBtn = document.getElementById('close-btn');
const outfitCount = document.getElementById('outfit-count');

// Modals
const deleteModal = document.getElementById('delete-modal');
const cancelDeleteBtn = document.getElementById('cancel-delete');
const confirmDeleteBtn = document.getElementById('confirm-delete');
const actionModal = document.getElementById('action-modal');
const wearOutfitBtn = document.getElementById('wear-outfit');
const deleteOutfitBtn = document.getElementById('delete-outfit');
const cancelActionBtn = document.getElementById('cancel-action');

// Listen for NUI messages
window.addEventListener('message', function(event) {
    const data = event.data;
    
    switch(data.action) {
        case 'open':
            openUI(data.outfits, data.maxOutfits);
            break;
        case 'close':
            closeUI();
            break;
        case 'updateOutfits':
            updateOutfits(data.outfits);
            break;
        case 'notify':
            showNotification(data.message, data.type);
            break;
    }
});

// Notifiche Custom
function showNotification(message, type = 'info') {
    const icons = {
        success: 'fas fa-check',
        error: 'fas fa-exclamation-triangle',
        info: 'fas fa-info-circle'
    };
    
    const titles = {
        success: 'Completato',
        error: 'Errore',
        info: 'Info'
    };
    
    const notification = document.createElement('div');
    notification.className = `custom-notification ${type}`;
    notification.innerHTML = `
        <div class="notification-icon">
            <i class="${icons[type] || icons.info}"></i>
        </div>
        <div class="notification-content">
            <div class="notification-title">${titles[type] || 'Outfit Bag'}</div>
            <div class="notification-message">${escapeHtml(message)}</div>
        </div>
        <div class="notification-progress"></div>
    `;
    
    notificationsContainer.appendChild(notification);
    
    // Auto-remove dopo 3 secondi
    setTimeout(() => {
        notification.classList.add('hiding');
        setTimeout(() => {
            if (notification.parentNode) {
                notification.parentNode.removeChild(notification);
            }
        }, 300);
    }, 3000);
}

// Open UI
function openUI(loadedOutfits, max) {
    outfits = loadedOutfits || [];
    maxOutfits = max || 5;
    container.classList.remove('hidden');
    renderOutfits();
    outfitNameInput.value = '';
    outfitNameInput.focus();
}

// Close UI
function closeUI() {
    container.classList.add('hidden');
    deleteModal.classList.add('hidden');
    actionModal.classList.add('hidden');
    outfitNameInput.value = '';
    selectedSlot = null;
}

// Update outfits list
function updateOutfits(newOutfits) {
    outfits = newOutfits || [];
    renderOutfits();
}

// Preview outfit - mostra temporaneamente l'outfit sul personaggio
function previewOutfit(outfit) {
    if (!outfit || !outfit.data) return;
    
    fetch(`https://${GetParentResourceName()}/previewOutfit`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ outfit: outfit.data })
    });
}

// Reset preview - torna all'outfit originale
function resetPreview() {
    fetch(`https://${GetParentResourceName()}/resetPreview`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    });
}

// Render outfit slots
function renderOutfits() {
    // Update count
    outfitCount.textContent = `${outfits.length}/${maxOutfits}`;
    
    // Disable save button if full
    saveBtn.disabled = outfits.length >= maxOutfits;
    
    // Get all slots
    const slots = outfitList.querySelectorAll('.outfit-slot');
    
    slots.forEach((slot, index) => {
        const outfit = outfits[index];
        
        // Rimuovi vecchi event listeners clonando
        const newSlot = slot.cloneNode(false);
        slot.parentNode.replaceChild(newSlot, slot);
        
        if (outfit) {
            // Slot riempito
            newSlot.classList.remove('empty');
            newSlot.classList.add('filled');
            newSlot.innerHTML = `
                <div class="slot-content">
                    <div class="outfit-info">
                        <div class="outfit-icon">
                            <i class="fas fa-tshirt"></i>
                        </div>
                        <div class="outfit-name">${escapeHtml(outfit.name)}</div>
                        <div class="outfit-date">${outfit.savedAt || ''}</div>
                    </div>
                </div>
                <div class="preview-hint">
                    <i class="fas fa-eye"></i> Preview
                </div>
            `;
            
            // Preview on hover
            newSlot.addEventListener('mouseenter', () => previewOutfit(outfit));
            newSlot.addEventListener('mouseleave', () => resetPreview());
            
            // Click handler per slot riempito
            newSlot.onclick = () => showActionMenu(index);
        } else {
            // Slot vuoto
            newSlot.classList.add('empty');
            newSlot.classList.remove('filled');
            newSlot.innerHTML = `
                <div class="slot-content">
                    <div class="empty-slot">
                        <i class="fas fa-plus"></i>
                    </div>
                </div>
            `;
            
            // Click handler per slot vuoto - salva outfit corrente
            newSlot.onclick = () => {
                if (outfits.length < maxOutfits) {
                    outfitNameInput.focus();
                    outfitNameInput.classList.add('pulse');
                    setTimeout(() => outfitNameInput.classList.remove('pulse'), 300);
                }
            };
        }
    });
}

// Show action menu for outfit
function showActionMenu(index) {
    selectedSlot = index;
    actionModal.classList.remove('hidden');
}

// Hide action menu
function hideActionMenu() {
    actionModal.classList.add('hidden');
    selectedSlot = null;
}

// Save current outfit
function saveOutfit() {
    const name = outfitNameInput.value.trim();
    
    if (!name) {
        outfitNameInput.classList.add('shake');
        setTimeout(() => outfitNameInput.classList.remove('shake'), 500);
        return;
    }
    
    if (outfits.length >= maxOutfits) {
        return;
    }
    
    fetch(`https://${GetParentResourceName()}/saveOutfit`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ name: name })
    }).then(response => response.json()).then(data => {
        if (data.success) {
            outfitNameInput.value = '';
        }
    });
}

// Load outfit
function loadOutfit() {
    if (selectedSlot === null) return;
    
    const outfit = outfits[selectedSlot];
    if (!outfit) return;
    
    fetch(`https://${GetParentResourceName()}/loadOutfit`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ outfit: outfit.data })
    });
    
    hideActionMenu();
}

// Show delete confirmation
function showDeleteConfirm() {
    if (selectedSlot === null) return;
    deleteIndex = selectedSlot;
    hideActionMenu();
    deleteModal.classList.remove('hidden');
}

// Hide delete modal
function hideDeleteModal() {
    deleteIndex = null;
    deleteModal.classList.add('hidden');
}

// Confirm delete
function confirmDelete() {
    if (deleteIndex === null) return;
    
    fetch(`https://${GetParentResourceName()}/deleteOutfit`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ index: deleteIndex + 1 }) // Lua is 1-indexed
    });
    
    hideDeleteModal();
}

// Close NUI
function closeNUI() {
    fetch(`https://${GetParentResourceName()}/close`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    });
}

// Utility: Escape HTML
function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

// Event Listeners
saveBtn.addEventListener('click', saveOutfit);

outfitNameInput.addEventListener('keypress', (e) => {
    if (e.key === 'Enter') {
        saveOutfit();
    }
});

closeBtn.addEventListener('click', closeNUI);

// Action menu
wearOutfitBtn.addEventListener('click', loadOutfit);
deleteOutfitBtn.addEventListener('click', showDeleteConfirm);
cancelActionBtn.addEventListener('click', hideActionMenu);

// Delete modal
cancelDeleteBtn.addEventListener('click', hideDeleteModal);
confirmDeleteBtn.addEventListener('click', confirmDelete);

// Click outside modals to close
actionModal.addEventListener('click', (e) => {
    if (e.target === actionModal) {
        hideActionMenu();
    }
});

deleteModal.addEventListener('click', (e) => {
    if (e.target === deleteModal) {
        hideDeleteModal();
    }
});

// ESC key handling
document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') {
        if (!actionModal.classList.contains('hidden')) {
            hideActionMenu();
        } else if (!deleteModal.classList.contains('hidden')) {
            hideDeleteModal();
        }
    }
});
