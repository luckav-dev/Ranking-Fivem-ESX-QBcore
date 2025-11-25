const CONFIG = {
    maxRows: 50,
    defaultAvatar: 'https://cdn.discordapp.com/embed/avatars/0.png'
};

let state = {
    isVisible: false,
    players: [],
    searchQuery: ''
};

const uiContainer = document.getElementById('ui-container');
const playerList = document.getElementById('player-list');
const searchInput = document.getElementById('search-input');

const MOCK_DATA = [
    { rank: 1, name: 'LegendaryPlayer', avatar: '', k: 5430, d: 120, a: 890 },
    { rank: 2, name: 'SniperWolf', avatar: '', k: 4300, d: 432, a: 1182 },
    { rank: 3, name: 'SpeedDemon', avatar: '', k: 3800, d: 500, a: 600 },
    { rank: 4, name: 'DriftKing', avatar: '', k: 3100, d: 600, a: 400 },
    { rank: 5, name: 'RoleplayGod', avatar: '', k: 2500, d: 700, a: 300 },
    { rank: 6, name: 'FiveM_Dev', avatar: '', k: 2100, d: 800, a: 200 },
    { rank: 7, name: 'PoliceChief', avatar: '', k: 1800, d: 900, a: 100 },
    { rank: 8, name: 'GangLeader', avatar: '', k: 1500, d: 1000, a: 50 },
    { rank: 9, name: 'Newbie', avatar: '', k: 1200, d: 1100, a: 25 },
    { rank: 10, name: 'Mechanic', avatar: '', k: 900, d: 1200, a: 10 }
];

document.addEventListener('DOMContentLoaded', () => {
    if (!window.invokeNative) {
        toggleUI(true);
        
        updateLeaderboard(MOCK_DATA);
        
        document.body.style.backgroundColor = '#333333';
        document.body.style.backgroundImage = 'url("./kush.png")';
        document.body.style.backgroundSize = 'cover';
        document.body.style.backgroundPosition = 'center top';
        document.body.style.backgroundRepeat = 'no-repeat';
    }
});




window.addEventListener('message', (event) => {
    const data = event.data;
    
    if (data.type === 'open') {
        toggleUI(true);
        if (data.players) {
            updateLeaderboard(data.players);
        }
    } else if (data.type === 'close') {
        toggleUI(false);
    } else if (data.type === 'updateData') {
        if (data.players) {
            updateLeaderboard(data.players);
        }
    }
});

document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape' && state.isVisible) {
        closeUI();
    }
});

searchInput.addEventListener('input', (e) => {
    state.searchQuery = e.target.value;
    renderRows();
});

function toggleUI(show) {
    state.isVisible = show;
    
    if (show) {
        uiContainer.classList.add('visible');
        searchInput.value = '';
        state.searchQuery = '';
    } else {
        uiContainer.classList.remove('visible');
        
        fetch(`https://${GetParentResourceName()}/close`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json; charset=UTF-8'
            },
            body: JSON.stringify({})
        }).catch(() => {});
    }
}

function closeUI() {
    toggleUI(false);
}

function updateLeaderboard(players) {
    state.players = players;
    renderRows();
}

function renderRows() {
    playerList.innerHTML = '';
    
    const filteredPlayers = state.players.filter(p => 
        p.name.toLowerCase().includes(state.searchQuery.toLowerCase())
    );
    
    filteredPlayers.forEach((player) => {
        const row = document.createElement('div');
        row.className = 'player-row';
        
        let rankClass = '';
        if (player.rank === 1) rankClass = 'rank-1';
        else if (player.rank === 2) rankClass = 'rank-2';
        else if (player.rank === 3) rankClass = 'rank-3';
        
        const kd = player.d > 0 ? (player.k / player.d).toFixed(2) : player.k;
        
        row.innerHTML = `
            <div class="rank ${rankClass}">${player.rank}°</div>
            <div class="player-info">
                <img class="avatar" src="${player.avatar || CONFIG.defaultAvatar}" 
                     onerror="this.src='${CONFIG.defaultAvatar}'" alt="${player.name}">
                <span class="username">${escapeHtml(player.name)}</span>
            </div>
            <div class="kda-stats">
                <div class="stat-item">
                    <div class="stat-label">K</div>
                    <div class="stat-val">${player.k}</div>
                </div>
                <div class="stat-item">
                    <div class="stat-label">D</div>
                    <div class="stat-val">${player.d}</div>
                </div>
                <div class="stat-item">
                    <div class="stat-label">A</div>
                    <div class="stat-val">${player.a}</div>
                </div>
            </div>
        `;
        
        playerList.appendChild(row);
    });
}

function escapeHtml(text) {
    const map = {
        '&': '&amp;',
        '<': '&lt;',
        '>': '&gt;',
        '"': '&quot;',
        "'": '&#039;'
    };
    return text.replace(/[&<>"']/g, (m) => map[m]);
}

function GetParentResourceName() {
    if (window.invokeNative) {
        return window.GetParentResourceName();
    }
    return 'ranking_system';
}
