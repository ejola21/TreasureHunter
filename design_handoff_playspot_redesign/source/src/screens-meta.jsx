// PlaySpot — meta screens: Mission List, Map Edit, Badges, Tutorial

// ─────────────────────────────────────────────────────────────
// SCREEN: Mission List — browse missions to play
// ─────────────────────────────────────────────────────────────
function ScreenMissionList({ tab = 'popular', onTab, onNav, onMission }) {
  const missions = [
    {
      title: 'Level 0 · I am a Beginner',
      desc: '시작하는 플레이어를 위한 입문 미션',
      loc: 'Seoul, South Korea',
      stars: 3, plays: 12, fails: 2, tint: 'green',
      badge: <PSIcons.Star size={28} color="#FFC800"/>,
      level: 0,
    },
    {
      title: 'Level 5 · Gambling',
      desc: '아이템 조합으로 운을 시험하는 미션',
      loc: 'Seoul, South Korea',
      stars: 3, plays: 24, fails: 9, tint: 'blue',
      badge: <PSIcons.Gem size={28}/>,
      level: 5,
    },
    {
      title: 'Basic Mission',
      desc: '지뢰, 달리기, 아이템 조합 기본기',
      loc: 'Korea Seoul',
      stars: 4, plays: 38, fails: 4, tint: 'orange',
      badge: <PSIcons.Flame size={28}/>,
      level: 2,
    },
    {
      title: 'Level 3 · Quiz & Solution',
      desc: '미션 퀴즈와 정답 아이템 활용법',
      loc: 'Seoul, South Korea',
      stars: 4, plays: 7, fails: 1, tint: 'purple',
      badge: <PSIcons.Trophy size={28}/>,
      level: 3,
    },
  ];

  return (
    <div className="ps-screen">
      <PSStatusBar/>
      {/* Header */}
      <div style={{
        padding: '8px 16px 12px',
        display: 'flex', alignItems: 'center', justifyContent: 'space-between',
        gap: 8,
      }}>
        <div className="ps-row" style={{ gap: 10 }}>
          <FoxMascot size={36} pose="wave"/>
          <div>
            <div className="ps-cap" style={{ fontSize: 9, color: 'var(--duo-hare)' }}>PLAYING NOW</div>
            <div style={{ fontFamily: 'var(--font-display)', fontWeight: 900, fontSize: 18, color: 'var(--duo-eel-2)' }}>
              Missions
            </div>
          </div>
        </div>
        <div className="ps-row" style={{ gap: 8 }}>
          <div style={{
            display: 'flex', alignItems: 'center', gap: 4,
            background: '#fff', border: '2px solid var(--duo-swan-2)',
            borderRadius: 999, padding: '4px 10px',
            boxShadow: '0 2px 0 0 var(--duo-swan-2)',
          }}>
            <PSIcons.Flame size={16}/>
            <span style={{ fontFamily: 'var(--font-display)', fontWeight: 900, fontSize: 14, color: 'var(--duo-fox)' }}>7</span>
          </div>
          <div style={{
            display: 'flex', alignItems: 'center', gap: 4,
            background: '#fff', border: '2px solid var(--duo-swan-2)',
            borderRadius: 999, padding: '4px 10px',
            boxShadow: '0 2px 0 0 var(--duo-swan-2)',
          }}>
            <PSIcons.Gem size={16}/>
            <span style={{ fontFamily: 'var(--font-display)', fontWeight: 900, fontSize: 14, color: 'var(--duo-beetle-deep)' }}>248</span>
          </div>
        </div>
      </div>

      {/* Segmented tabs */}
      <div className="ps-tabs">
        <button className={`ps-tab ${tab === 'popular' ? 'active' : ''}`} onClick={() => onTab?.('popular')}>POPULAR</button>
        <button className={`ps-tab ${tab === 'new' ? 'active' : ''}`} onClick={() => onTab?.('new')}>NEW</button>
        <button className={`ps-tab ${tab === 'near' ? 'active' : ''}`} onClick={() => onTab?.('near')}>NEAR ME</button>
      </div>

      {/* List */}
      <div style={{ flex: 1, overflow: 'auto', padding: '14px 14px 8px', background: 'var(--duo-snow)' }}>
        <div className="ps-col" style={{ gap: 12 }}>
          {missions.map((m, i) => <MissionCard key={i} m={m} onClick={onMission}/>)}
        </div>
      </div>

      {/* Bottom nav */}
      <div className="ps-nav">
        {[
          { id: 'list', icon: <PSIcons.List size={22}/>, label: 'LIST', active: true },
          { id: 'info', icon: <PSIcons.User size={22}/>, label: 'ME' },
          { id: 'badge', icon: <PSIcons.Badge size={22}/>, label: 'BADGES' },
          { id: 'design', icon: <PSIcons.Pencil size={22}/>, label: 'DESIGN' },
          { id: 'help', icon: <PSIcons.Help size={22}/>, label: 'HELP' },
        ].map(t => (
          <div key={t.id} className={`ps-nav-item ${t.active ? 'active' : ''}`}
               onClick={() => onNav?.(t.id)}>
            <div style={{ color: t.active ? 'var(--duo-macaw)' : 'var(--duo-hare)' }}>{t.icon}</div>
            <div>{t.label}</div>
          </div>
        ))}
      </div>
    </div>
  );
}

function MissionCard({ m, onClick }) {
  const tints = {
    green:  { bg: '#dff8c5', deep: '#43A601', mid: '#93e85c' },
    blue:   { bg: '#d2effd', deep: '#0084c2', mid: '#77d0fa' },
    orange: { bg: '#ffe7ce', deep: '#a55e00', mid: '#ffb766' },
    purple: { bg: '#eed4ff', deep: '#8c39c8', mid: '#ce82ff' },
  };
  const t = tints[m.tint] || tints.green;
  return (
    <button onClick={onClick} style={{
      width: '100%', textAlign: 'left',
      background: '#fff',
      border: '2px solid var(--duo-swan-2)',
      borderRadius: 14,
      boxShadow: '0 3px 0 0 var(--duo-swan-2)',
      padding: 10,
      display: 'flex', gap: 12, alignItems: 'center',
      cursor: 'pointer',
    }}>
      {/* Avatar tile */}
      <div style={{
        width: 64, height: 64, flex: 'none',
        background: t.bg,
        border: `2px solid ${t.mid}`,
        borderRadius: 14,
        boxShadow: `0 2px 0 0 ${t.mid}`,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        position: 'relative',
      }}>
        {m.badge}
        {/* Level circle */}
        <div style={{
          position: 'absolute', top: -8, right: -8,
          width: 26, height: 26, borderRadius: '50%',
          background: t.deep, color: '#fff',
          fontFamily: 'var(--font-display)', fontWeight: 900, fontSize: 13,
          border: '2px solid #fff',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}>{m.level}</div>
      </div>

      {/* Text */}
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{
          fontFamily: 'var(--font-display)', fontWeight: 900,
          fontSize: 14, color: 'var(--duo-eel-2)', lineHeight: 1.15,
        }}>{m.title}</div>
        <div style={{
          fontSize: 11, color: 'var(--duo-wolf-2)',
          marginTop: 3, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis',
        }}>{m.desc}</div>
        <div className="ps-row" style={{ marginTop: 6, gap: 6, flexWrap: 'wrap' }}>
          {Array.from({length: 5}).map((_, i) =>
            <PSIcons.Star key={i} size={11} color={i < m.stars ? '#FFC800' : '#e5e5e5'}/>
          )}
          <span style={{
            fontFamily: 'var(--font-display)', fontWeight: 800, fontSize: 9,
            letterSpacing: '0.05em', color: 'var(--duo-macaw)', marginLeft: 4,
          }}>{m.loc.toUpperCase()}</span>
        </div>
      </div>

      {/* Play/Fail count */}
      <div style={{ textAlign: 'right', flex: 'none' }}>
        <div className="ps-chip" style={{
          background: 'var(--duo-green-100)', color: 'var(--duo-green-800)',
          height: 22, padding: '0 8px', fontSize: 10,
        }}>{m.plays} PLAYS</div>
        <div style={{ height: 4 }}/>
        <div className="ps-chip" style={{
          background: 'var(--duo-cardinal-bg)', color: 'var(--duo-cardinal-deep)',
          height: 22, padding: '0 8px', fontSize: 10,
        }}>{m.fails} FAILS</div>
      </div>
    </button>
  );
}


// ─────────────────────────────────────────────────────────────
// SCREEN: Map Edit — place / drag / configure items on the map
// ─────────────────────────────────────────────────────────────
function ScreenMapEdit({ onCancel, onSave, onItemTap }) {
  return (
    <div className="ps-screen">
      <PSStatusBar/>
      {/* Top action bar */}
      <div style={{
        display: 'flex', alignItems: 'center', gap: 8,
        padding: '6px 12px 10px',
      }}>
        <button onClick={onCancel} className="ps-btn ps-btn--ghost ps-btn--sm" style={{ width: 70 }}>CANCEL</button>
        <div className="ps-grow" style={{ textAlign: 'center' }}>
          <div className="ps-cap" style={{ fontSize: 9, color: 'var(--duo-hare)' }}>EDITING</div>
          <div style={{ fontFamily: 'var(--font-display)', fontWeight: 900, fontSize: 15, color: 'var(--duo-eel-2)' }}>
            미션 설계 · Design
          </div>
        </div>
        <button onClick={onSave} className="ps-btn ps-btn--primary ps-btn--sm" style={{ width: 70 }}>SAVE</button>
      </div>

      {/* Map area */}
      <div style={{ flex: 1, position: 'relative', overflow: 'hidden', background: '#c9d9ad' }}>
        {/* Park-ish bg with paths */}
        <svg width="100%" height="100%" viewBox="0 0 320 480" preserveAspectRatio="none" style={{ position: 'absolute', inset: 0 }}>
          <rect width="320" height="480" fill="#c9d9ad"/>
          <path d="M-20 100 Q160 80 340 130" stroke="#fff" strokeWidth="14" fill="none"/>
          <path d="M-20 100 Q160 80 340 130" stroke="#a8b58a" strokeWidth="16" fill="none" opacity="0.4"/>
          <path d="M0 440 Q120 380 200 420 Q260 440 340 400" stroke="#FFE99A" strokeWidth="18" fill="none"/>
          <path d="M-10 460 Q150 410 340 440" stroke="#fff" strokeWidth="3" fill="none" opacity="0.7"/>
        </svg>
        {/* Sheep Meadow label */}
        <div style={{ position: 'absolute', left: 165, top: 145, fontSize: 11, color: '#6b7d4d', fontWeight: 700 }}>Sheep Meadow</div>

        {/* Active mission radius */}
        <div style={{
          position: 'absolute', left: 60, top: 140, width: 220, height: 220,
          borderRadius: '50%', background: 'rgba(28,176,246,0.12)',
          border: '2px dashed rgba(28,176,246,0.6)',
        }}/>

        {/* Mine "blast" zones */}
        <div style={{
          position: 'absolute', left: 195, top: 160, width: 70, height: 70,
          borderRadius: '50%', background: 'rgba(255,75,75,0.25)',
        }}/>
        <div style={{
          position: 'absolute', left: 30, top: 270, width: 80, height: 80,
          borderRadius: '50%', background: 'rgba(255,75,75,0.25)',
        }}/>
        <div style={{
          position: 'absolute', left: 160, top: 380, width: 70, height: 70,
          borderRadius: '50%', background: 'rgba(255,75,75,0.25)',
        }}/>

        {/* Item pins, scattered */}
        {[
          { l: 90, t: 170, kind: 'defence' },
          { l: 150, t: 150, kind: 'stealthRadar' },
          { l: 220, t: 170, kind: 'mine' },
          { l: 40, t: 290, kind: 'mine' },
          { l: 110, t: 230, kind: 'hint' },
          { l: 200, t: 220, kind: 'gambling' },
          { l: 250, t: 260, kind: 'hint' },
          { l: 130, t: 280, kind: 'mine' },
          { l: 175, t: 270, kind: 'defence' },
          { l: 80, t: 310, kind: 'quiz' },
          { l: 130, t: 320, kind: 'solution' },
          { l: 220, t: 320, kind: 'quiz' },
          { l: 180, t: 390, kind: 'mine' },
          { l: 155, t: 240, kind: 'gambling' },
        ].map((p, i) => (
          <div key={i} onClick={() => onItemTap?.(p.kind)} style={{ position: 'absolute', left: p.l, top: p.t, cursor: 'pointer' }}>
            <ItemPin kind={p.kind} size={32} active={i % 3 === 0}/>
          </div>
        ))}

        {/* Target reticle */}
        <div style={{
          position: 'absolute', left: 175, top: 250, width: 28, height: 28,
          borderRadius: '50%', background: '#000',
          border: '3px solid #fff',
          boxShadow: '0 0 0 2px rgba(0,0,0,0.6)',
        }}/>
        {/* checkered flag */}
        <div style={{ position: 'absolute', left: 36, top: 220 }}>
          <svg width="36" height="44" viewBox="0 0 36 44">
            <line x1="6" y1="2" x2="6" y2="42" stroke="#3c3c3c" strokeWidth="2.5"/>
            <path d="M6 4 L30 4 L30 22 L6 22 Z" fill="#fff"/>
            <rect x="6" y="4" width="6" height="6" fill="#3c3c3c"/>
            <rect x="18" y="4" width="6" height="6" fill="#3c3c3c"/>
            <rect x="12" y="10" width="6" height="6" fill="#3c3c3c"/>
            <rect x="24" y="10" width="6" height="6" fill="#3c3c3c"/>
            <rect x="6" y="16" width="6" height="6" fill="#3c3c3c"/>
            <rect x="18" y="16" width="6" height="6" fill="#3c3c3c"/>
          </svg>
        </div>

        {/* Helper toast */}
        <div style={{
          position: 'absolute', left: 12, right: 12, bottom: 12,
          background: 'var(--duo-eel-2)',
          color: '#fff',
          padding: '10px 12px',
          borderRadius: 14,
          boxShadow: '0 4px 0 0 rgba(0,0,0,0.35)',
          display: 'flex', alignItems: 'center', gap: 10,
        }}>
          <FoxMascot size={28} pose="think"/>
          <div style={{ fontSize: 11, lineHeight: 1.35 }}>
            <span style={{ color: 'var(--duo-bee)', fontWeight: 800 }}>꾹 눌러서</span> 아이템 이동 ·
            <span style={{ color: 'var(--duo-macaw)', fontWeight: 800 }}> 탭</span> 으로 설정
          </div>
        </div>
      </div>

      {/* Item palette dock */}
      <div style={{
        background: '#fff',
        borderTop: '2px solid var(--duo-swan)',
        padding: '8px 10px 10px',
      }}>
        <div className="ps-cap" style={{ fontSize: 9, color: 'var(--duo-hare)', marginBottom: 6 }}>
          ITEM PALETTE — DRAG TO MAP
        </div>
        <div style={{ display: 'flex', gap: 4, overflowX: 'auto' }}>
          {['quiz', 'mine', 'defence', 'hint', 'gambling', 'solution', 'mapRadar', 'mineRadar', 'stealthRadar', 'allRadar', 'runStart', 'runEnd', 'dark', 'store'].map(k => (
            <div key={k} style={{
              flex: 'none', width: 44, padding: '4px 0',
              border: '2px solid var(--duo-swan-2)', borderRadius: 10,
              background: '#fff',
              display: 'flex', flexDirection: 'column', alignItems: 'center',
            }}>
              <ItemPin kind={k} size={28}/>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}


// ─────────────────────────────────────────────────────────────
// SCREEN: Badge Collection
// ─────────────────────────────────────────────────────────────
function ScreenBadges({ onNav }) {
  return (
    <div className="ps-screen">
      <PSStatusBar/>

      {/* Header */}
      <div style={{ padding: '8px 16px 14px' }}>
        <div className="ps-row" style={{ justifyContent: 'space-between', alignItems: 'center' }}>
          <div>
            <div className="ps-cap" style={{ fontSize: 9, color: 'var(--duo-hare)' }}>YOUR COLLECTION</div>
            <div style={{ fontFamily: 'var(--font-display)', fontWeight: 900, fontSize: 22, color: 'var(--duo-eel-2)' }}>
              Badges
            </div>
          </div>
          <div style={{ position: 'relative' }}>
            <FoxMascot size={48} pose="cheer"/>
          </div>
        </div>
      </div>

      {/* Progress strip */}
      <div style={{ padding: '0 16px 12px' }}>
        <div style={{
          background: '#fff', border: '2px solid var(--duo-swan-2)',
          borderRadius: 16, boxShadow: '0 2px 0 0 var(--duo-swan-2)',
          padding: 12,
        }}>
          <div className="ps-row" style={{ justifyContent: 'space-between', marginBottom: 8 }}>
            <div style={{ fontFamily: 'var(--font-display)', fontWeight: 900, fontSize: 13, color: 'var(--duo-eel-2)' }}>
              4 / 12 unlocked
            </div>
            <div style={{ fontFamily: 'var(--font-display)', fontWeight: 900, fontSize: 13, color: 'var(--duo-fox)' }}>
              33%
            </div>
          </div>
          <div style={{ height: 12, background: 'var(--duo-swan)', borderRadius: 999, overflow: 'hidden' }}>
            <div style={{ width: '33%', height: '100%', background: 'var(--duo-fox)', borderRadius: 999, boxShadow: 'inset 0 -3px 0 0 rgba(0,0,0,0.15)' }}/>
          </div>
        </div>
      </div>

      <div style={{ flex: 1, overflow: 'auto', padding: '0 16px 14px' }}>
        {/* Mission Badge group */}
        <BadgeGroup
          title="Mission Badges"
          subtitle="미션 뱃지"
          tint="green"
          badges={[
            { title: 'Beginner', sub: 'Level 0', unlocked: true, color: '#FFE3A8', icon: <PSIcons.Star size={36} color="#FF9600"/> },
            { title: 'Tiananmen', sub: 'Beijing', unlocked: true, color: '#C7615A', icon: <PSIcons.Trophy size={36}/> },
            { title: 'Opera House', sub: 'Sydney', unlocked: true, color: '#2a6cb8', icon: <PSIcons.Star size={36} color="#fff"/> },
            { title: 'Runner', sub: 'Level 2', unlocked: true, color: '#FFE3A8', icon: <PSIcons.Bolt size={36}/> },
            { title: '???', sub: 'Locked', unlocked: false, color: '#bbb' },
            { title: '???', sub: 'Locked', unlocked: false, color: '#bbb' },
          ]}/>

        {/* Play Badge group */}
        <BadgeGroup
          title="Play Badges"
          subtitle="플레이 뱃지"
          tint="purple"
          badges={[
            { title: '5-Streak', sub: '5 days', unlocked: true, color: '#FF9600', icon: <PSIcons.Flame size={36}/> },
            { title: 'Hunter', sub: '50 spots', unlocked: false, color: '#bbb' },
            { title: 'Quizmaster', sub: '20 correct', unlocked: false, color: '#bbb' },
            { title: 'Stealth', sub: '0 mines', unlocked: false, color: '#bbb' },
          ]}/>
      </div>

      {/* Bottom nav */}
      <div className="ps-nav">
        {[
          { id: 'list', icon: <PSIcons.List size={22}/>, label: 'LIST' },
          { id: 'info', icon: <PSIcons.User size={22}/>, label: 'ME' },
          { id: 'badge', icon: <PSIcons.Badge size={22}/>, label: 'BADGES', active: true },
          { id: 'design', icon: <PSIcons.Pencil size={22}/>, label: 'DESIGN' },
          { id: 'help', icon: <PSIcons.Help size={22}/>, label: 'HELP' },
        ].map(t => (
          <div key={t.id} className={`ps-nav-item ${t.active ? 'active' : ''}`} onClick={() => onNav?.(t.id)}>
            <div style={{ color: t.active ? 'var(--duo-macaw)' : 'var(--duo-hare)' }}>{t.icon}</div>
            <div>{t.label}</div>
          </div>
        ))}
      </div>
    </div>
  );
}

function BadgeGroup({ title, subtitle, badges, tint = 'green' }) {
  const tints = {
    green:  { fill: 'var(--duo-green-500)', deep: 'var(--duo-green-700)' },
    purple: { fill: 'var(--duo-beetle)',     deep: 'var(--duo-beetle-deep)' },
  };
  const t = tints[tint];
  return (
    <div style={{
      background: '#fff', border: '2px solid var(--duo-swan-2)',
      borderRadius: 18, boxShadow: '0 2px 0 0 var(--duo-swan-2)',
      marginBottom: 14, overflow: 'hidden',
    }}>
      {/* Header pill */}
      <div style={{
        background: t.fill, padding: '10px 14px',
        boxShadow: `inset 0 -3px 0 0 ${t.deep}`,
        display: 'flex', alignItems: 'center', gap: 8,
      }}>
        <div className="ps-cap" style={{ fontSize: 10, color: '#fff', letterSpacing: '0.06em' }}>
          {subtitle}
        </div>
        <div style={{ flex: 1 }}/>
        <div style={{ fontFamily: 'var(--font-display)', fontWeight: 900, fontSize: 14, color: '#fff' }}>
          {title}
        </div>
      </div>
      <div style={{
        display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 8,
        padding: 10,
      }}>
        {badges.map((b, i) => <BadgeItem key={i} b={b}/>)}
      </div>
    </div>
  );
}

function BadgeItem({ b }) {
  return (
    <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 4 }}>
      <div style={{
        width: 68, height: 68, borderRadius: '50%',
        background: b.unlocked ? b.color : 'repeating-linear-gradient(45deg, #d9d9d9 0 4px, #ececec 4px 8px)',
        border: `3px solid ${b.unlocked ? '#3c3c3c' : '#aaa'}`,
        boxShadow: b.unlocked ? '0 4px 0 0 rgba(0,0,0,0.2)' : '0 2px 0 0 rgba(0,0,0,0.1)',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        position: 'relative',
        filter: b.unlocked ? 'none' : 'grayscale(1)',
      }}>
        {b.unlocked ? b.icon : <PSIcons.Help size={32} color="#fff"/>}
        {!b.unlocked && (
          <div style={{
            position: 'absolute', bottom: -4, right: -4,
            width: 24, height: 24, borderRadius: '50%',
            background: '#fff', border: '2px solid var(--duo-swan-2)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            boxShadow: '0 2px 0 0 var(--duo-swan-2)',
          }}>
            <svg width="12" height="14" viewBox="0 0 12 14" fill="var(--duo-hare)">
              <path d="M3 6V4a3 3 0 0 1 6 0v2h1v7H2V6h1zm2 0h2V4a1 1 0 0 0-2 0v2z"/>
            </svg>
          </div>
        )}
      </div>
      <div style={{
        fontFamily: 'var(--font-display)', fontWeight: 900,
        fontSize: 11, color: b.unlocked ? 'var(--duo-eel-2)' : 'var(--duo-hare)',
        textAlign: 'center', lineHeight: 1.2,
      }}>{b.title}</div>
      <div style={{ fontSize: 9, color: 'var(--duo-hare)' }}>{b.sub}</div>
    </div>
  );
}


// ─────────────────────────────────────────────────────────────
// SCREEN: Tutorial — 3 step onboarding
// ─────────────────────────────────────────────────────────────
function ScreenTutorial({ step = 1, onStep, onDone }) {
  const steps = [
    {
      kicker: 'STEP 1 · 지도에 아이템 배치',
      title: 'Drag items onto the map',
      tip: '꾹 누르고 드래그하면 아이템이 이동합니다.',
      tipTo: { left: 60, top: 90, kind: 'quiz' },
      pose: 'wave',
      foxLine: '아래 아이템을 끌어서 지도에 놓아보세요!',
    },
    {
      kicker: 'STEP 2 · 아이템 세부 설정',
      title: 'Tap to configure',
      tip: '탭하면 세부 설정 패널이 열립니다.',
      tipTo: { left: 160, top: 90, kind: 'quiz' },
      pose: 'think',
      foxLine: '퀴즈 문제와 정답을 직접 적을 수 있어요.',
    },
    {
      kicker: 'STEP 3 · 미션 설정',
      title: 'Name your mission',
      tip: '미션 제목과 설명, 장소를 정해 저장하세요.',
      tipTo: { left: 60, top: 180, kind: 'item' },
      pose: 'cheer',
      foxLine: '준비 완료! Save를 누르면 친구들과 공유할 수 있어요.',
    },
  ];
  const s = steps[step - 1];

  return (
    <div className="ps-screen">
      <PSStatusBar/>

      {/* Step header */}
      <div style={{
        padding: '8px 16px 6px',
        display: 'flex', alignItems: 'center', justifyContent: 'space-between',
      }}>
        <button onClick={onDone} className="ps-btn ps-btn--ghost ps-btn--sm" style={{ width: 56 }}>SKIP</button>
        <div className="ps-row" style={{ gap: 4 }}>
          {[1,2,3].map(i => (
            <div key={i} style={{
              width: i === step ? 22 : 8, height: 8, borderRadius: 4,
              background: i === step ? 'var(--duo-macaw)' : 'var(--duo-swan)',
              transition: 'width 0.2s',
            }}/>
          ))}
        </div>
        <button onClick={onDone} className="ps-btn ps-btn--ghost ps-btn--sm ps-btn--icon">
          <PSIcons.Close size={18} color="var(--duo-wolf)"/>
        </button>
      </div>

      {/* Title */}
      <div style={{ padding: '6px 18px 0' }}>
        <div className="ps-cap" style={{ fontSize: 10, color: 'var(--duo-fox)', letterSpacing: '0.08em' }}>
          {s.kicker}
        </div>
        <div className="ps-display" style={{ fontSize: 22, marginTop: 4, color: 'var(--duo-eel-2)' }}>
          {s.title}
        </div>
      </div>

      {/* Faux device demo area */}
      <div style={{ padding: '16px 18px 0', flex: 1, minHeight: 0 }}>
        <div style={{
          position: 'relative',
          background: '#e7eed4', borderRadius: 14,
          border: '2px solid var(--duo-swan-2)',
          boxShadow: '0 3px 0 0 var(--duo-swan-2)',
          height: '100%', overflow: 'hidden',
        }}>
          {/* mini map content */}
          <svg width="100%" height="100%" viewBox="0 0 280 320" preserveAspectRatio="none" style={{ position: 'absolute', inset: 0 }}>
            <path d="M0 80 Q140 60 280 100" stroke="#fff" strokeWidth="14" fill="none"/>
            <path d="M-10 220 Q120 200 290 240" stroke="#fff" strokeWidth="12" fill="none"/>
            <rect x="30" y="120" width="50" height="40" rx="3" fill="#f0e6cf" stroke="#cabd96"/>
            <rect x="180" y="50" width="60" height="50" rx="3" fill="#f0e6cf" stroke="#cabd96"/>
            <rect x="100" y="180" width="80" height="60" rx="3" fill="#f0e6cf" stroke="#cabd96"/>
          </svg>
          {/* Pin to highlight */}
          <div style={{ position: 'absolute', left: s.tipTo.left, top: s.tipTo.top }}>
            <div style={{ position: 'relative' }}>
              <div className="ps-pulse-ring" style={{ inset: -10, borderColor: 'var(--duo-fox)' }}/>
              <ItemPin kind={s.tipTo.kind} size={40} active glow/>
            </div>
          </div>
          {/* Pointing hand */}
          {step === 1 && (
            <div style={{ position: 'absolute', left: s.tipTo.left + 30, top: s.tipTo.top + 30, fontSize: 36 }}>
              <svg width="44" height="44" viewBox="0 0 24 24" fill="#FF9600" stroke="#a04600" strokeWidth="1">
                <path d="M9 2 L9 12 L7 12 L4 16 L4 20 L8 22 L16 22 L20 18 L20 10 L18 10 L18 13 L16 13 L16 8 L14 8 L14 13 L12 13 L12 2 Z"/>
              </svg>
            </div>
          )}
          {/* Tap ripple */}
          {step === 2 && (
            <div style={{ position: 'absolute', left: s.tipTo.left + 10, top: s.tipTo.top + 10 }}>
              <div style={{ width: 40, height: 40, borderRadius: '50%', border: '3px solid var(--duo-macaw)', opacity: 0.6 }}/>
            </div>
          )}

          {/* Tip bubble */}
          <div className="ps-bubble dn" style={{
            position: 'absolute', left: 14, top: 14, maxWidth: 200,
            background: 'var(--duo-bee-bg)',
            borderColor: 'var(--duo-bee-deep)',
            boxShadow: '0 2px 0 0 var(--duo-bee-deep)',
          }}>
            <div style={{ fontSize: 12, color: 'var(--duo-eel-2)' }}>{s.tip}</div>
          </div>
        </div>
      </div>

      {/* Fox + speech bubble */}
      <div style={{
        padding: '14px 16px',
        display: 'flex', alignItems: 'flex-end', gap: 8,
      }}>
        <FoxMascot size={64} pose={s.pose}/>
        <div className="ps-bubble" style={{
          flex: 1, marginBottom: 6,
        }}>
          {s.foxLine}
          <span style={{
            position: 'absolute',
            left: -10, bottom: 14,
            width: 14, height: 14, background: '#fff',
            borderLeft: '2px solid var(--duo-swan-2)',
            borderBottom: '2px solid var(--duo-swan-2)',
            transform: 'rotate(45deg)',
          }}/>
        </div>
      </div>

      {/* Nav buttons */}
      <div style={{ padding: '0 16px 16px', display: 'flex', gap: 8 }}>
        {step > 1 && (
          <button onClick={() => onStep?.(step - 1)} className="ps-btn ps-btn--ghost" style={{ flex: 1 }}>
            <PSIcons.ArrowLeft size={16} color="var(--duo-wolf)"/> BACK
          </button>
        )}
        {step < 3 && (
          <button onClick={() => onStep?.(step + 1)} className="ps-btn ps-btn--primary" style={{ flex: 1 }}>
            NEXT
          </button>
        )}
        {step === 3 && (
          <button onClick={onDone} className="ps-btn ps-btn--primary" style={{ flex: 1 }}>
            LET'S PLAY!
          </button>
        )}
      </div>
    </div>
  );
}

Object.assign(window, {
  ScreenMissionList, ScreenMapEdit, ScreenBadges, ScreenTutorial,
});
