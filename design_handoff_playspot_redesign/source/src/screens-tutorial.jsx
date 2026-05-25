// PlaySpot — Tutorial / Help screens (3 long-form pages)
// Replaces the simple 3-step onboarding with proper redesigned versions of
// the original tutorial pages: Item Glossary, How to Play, Mission Design.

// ─────────────────────────────────────────────────────────────
// SCREEN: Item Glossary — all in-game items, grouped by family
// ─────────────────────────────────────────────────────────────
function ScreenItemGlossary({ onBack, onNav, onTab }) {
  // Build sections from GAME_ITEMS metadata
  const groups = [
    { id: 'core',  title: 'Mission · 핵심',  subtitle: '미션 진행에 필요한 아이템',
      keys: ['start', 'end', 'hint', 'mine', 'defence', 'gambling'], tint: 'green' },
    { id: 'quiz',  title: 'Quiz · 퀴즈',     subtitle: '퀴즈 풀이용 아이템',
      keys: ['quiz', 'solution', 'oxO', 'oxX'], tint: 'red' },
    { id: 'radar', title: 'Radar · 레이더',  subtitle: '숨겨진 아이템을 보여주는 도구',
      keys: ['mapRadar', 'mineRadar', 'stealthRadar', 'allRadar'], tint: 'purple' },
    { id: 'time',  title: 'Time · 시간',     subtitle: '제한 시간 도전',
      keys: ['runStart', 'runEnd'], tint: 'blue' },
    { id: 'mod',   title: 'Special · 특수',  subtitle: '특수 효과 아이템',
      keys: ['dark', 'store', 'coupon', 'hospital'], tint: 'orange' },
  ];

  return (
    <div className="ps-screen">
      <PSStatusBar/>

      {/* Sticky title bar */}
      <div style={{
        padding: '4px 12px 10px',
        display: 'flex', alignItems: 'center', gap: 8,
        borderBottom: '2px solid var(--duo-swan)',
        background: '#fff',
      }}>
        <button onClick={onBack} className="ps-btn ps-btn--ghost ps-btn--sm ps-btn--icon">
          <PSIcons.ArrowLeft size={18} color="var(--duo-wolf)"/>
        </button>
        <div className="ps-grow">
          <div className="ps-cap" style={{ fontSize: 9, color: 'var(--duo-hare)' }}>
            HELP · 도움말
          </div>
          <div style={{ fontFamily: 'var(--font-display)', fontWeight: 900, fontSize: 17, color: 'var(--duo-eel-2)', lineHeight: 1.1 }}>
            Item Glossary
          </div>
        </div>
        <div style={{ width: 36 }}/>
      </div>

      {/* Top tabs across the 3 tutorial pages */}
      <div className="ps-tabs" style={{ borderBottom: 'none', padding: '8px 12px 4px' }}>
        <button className="ps-tab active">ITEMS</button>
        <button className="ps-tab" onClick={() => onTab?.('howto')}>HOW TO PLAY</button>
        <button className="ps-tab" onClick={() => onTab?.('design')}>DESIGN</button>
      </div>

      {/* Scroll body */}
      <div style={{ flex: 1, overflow: 'auto', padding: '8px 12px 16px', background: 'var(--duo-snow)' }}>

        {/* Property legend card */}
        <div className="ps-card" style={{ padding: 12, marginBottom: 14, borderRadius: 14 }}>
          <div className="ps-cap" style={{ fontSize: 10, color: 'var(--duo-fox)', marginBottom: 8, letterSpacing: '0.08em' }}>
            아이템 속성 · PROPERTIES
          </div>
          <PropRow label="Normal"  desc="지도와 AR 화면 모두에서 볼 수 있어요"
            badge={<div style={{ width: 14, height: 14, borderRadius: '50%', background: 'var(--duo-macaw)', border: '2px solid #2D3339' }}/>}/>
          <PropRow label="Hidden"  desc="지도 화면에서는 보이지 않아요"
            badge={<div style={{ width: 14, height: 14, borderRadius: '50%', background: '#fff', border: '2px dashed var(--duo-macaw)' }}/>}/>
          <PropRow label="Stealth" desc="AR 레이더에도 정보를 숨겨요"
            badge={<div style={{ width: 14, height: 14, borderRadius: '50%', background: 'var(--duo-eel-2)', border: '2px solid #2D3339' }}/>}/>
          <PropRow label="필수 ★"  desc="미션 성공에 꼭 필요한 아이템 — 별이 달려요"
            badge={
              <svg width="18" height="18" viewBox="0 0 24 24">
                <circle cx="12" cy="12" r="10" fill="#FFC800" stroke="#2D3339" strokeWidth="2"/>
                <path d="M12 6 L14 11 L19 11 L15 14 L17 19 L12 16 L7 19 L9 14 L5 11 L10 11 Z" fill="#fff"/>
              </svg>
            }/>
        </div>

        {/* Groups */}
        {groups.map(g => <ItemGroup key={g.id} group={g}/>)}

      </div>

      {/* Bottom nav */}
      <div className="ps-nav">
        {[
          { id: 'list', icon: <PSIcons.List size={22}/>, label: 'LIST' },
          { id: 'info', icon: <PSIcons.User size={22}/>, label: 'ME' },
          { id: 'badge', icon: <PSIcons.Badge size={22}/>, label: 'BADGES' },
          { id: 'design', icon: <PSIcons.Pencil size={22}/>, label: 'DESIGN' },
          { id: 'help', icon: <PSIcons.Help size={22}/>, label: 'HELP', active: true },
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

function PropRow({ label, desc, badge }) {
  return (
    <div style={{ display: 'flex', alignItems: 'flex-start', gap: 10, padding: '5px 0' }}>
      <div style={{ width: 22, display: 'flex', alignItems: 'center', justifyContent: 'center', paddingTop: 1 }}>{badge}</div>
      <div style={{ flex: 1 }}>
        <span style={{
          fontFamily: 'var(--font-display)', fontWeight: 900,
          fontSize: 13, color: 'var(--duo-eel-2)',
        }}>{label}</span>
        <span style={{ fontSize: 12, color: 'var(--duo-wolf-2)', marginLeft: 8 }}>{desc}</span>
      </div>
    </div>
  );
}

function ItemGroup({ group }) {
  const tints = {
    green:  { fill: 'var(--duo-green-500)', deep: 'var(--duo-green-700)' },
    red:    { fill: 'var(--duo-cardinal)',  deep: '#C12626' },
    purple: { fill: 'var(--duo-beetle)',     deep: 'var(--duo-beetle-deep)' },
    blue:   { fill: 'var(--duo-macaw)',     deep: '#0084c2' },
    orange: { fill: 'var(--duo-fox)',        deep: 'var(--duo-fox-deep)' },
  };
  const t = tints[group.tint] || tints.green;
  return (
    <div style={{
      background: '#fff', border: '2px solid var(--duo-swan-2)',
      borderRadius: 16, boxShadow: '0 2px 0 0 var(--duo-swan-2)',
      marginBottom: 14, overflow: 'hidden',
    }}>
      {/* Header */}
      <div style={{
        background: t.fill, padding: '8px 14px',
        boxShadow: `inset 0 -3px 0 0 ${t.deep}`,
        display: 'flex', alignItems: 'baseline', gap: 8,
      }}>
        <div style={{
          fontFamily: 'var(--font-display)', fontWeight: 900,
          fontSize: 14, color: '#fff', letterSpacing: '0.02em',
        }}>{group.title}</div>
        <div className="ps-cap" style={{ fontSize: 9, color: 'rgba(255,255,255,0.8)' }}>
          {group.subtitle}
        </div>
      </div>
      {/* Items */}
      <div>
        {group.keys.map((key, i) => {
          const item = GAME_ITEMS[key];
          if (!item) return null;
          return (
            <div key={key} style={{
              display: 'flex', alignItems: 'center', gap: 12,
              padding: '10px 12px',
              borderTop: i > 0 ? '1px solid var(--duo-swan)' : 'none',
            }}>
              <div style={{ flex: 'none', width: 50, display: 'flex', justifyContent: 'center' }}>
                <ItemPin kind={key} size={42}/>
              </div>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ display: 'flex', alignItems: 'baseline', gap: 6, flexWrap: 'wrap' }}>
                  <span style={{
                    fontFamily: 'var(--font-display)', fontWeight: 900,
                    fontSize: 14, color: 'var(--duo-eel-2)',
                  }}>{item.name}</span>
                  <span style={{ fontSize: 10, color: 'var(--duo-hare)' }}>
                    {item.nameKo}
                  </span>
                  {item.essential && (
                    <span className="ps-chip" style={{
                      background: 'var(--duo-bee-bg)', color: '#a87a00',
                      height: 18, padding: '0 6px', fontSize: 9,
                    }}>필수</span>
                  )}
                </div>
                <div style={{
                  fontSize: 11.5, color: 'var(--duo-wolf-2)',
                  marginTop: 2, lineHeight: 1.35,
                }}>{item.desc}</div>
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}


// ─────────────────────────────────────────────────────────────
// SCREEN: How to Play — what's PlaySpot, modes, gameplay flow
// ─────────────────────────────────────────────────────────────
function ScreenHowToPlay({ onBack, onNav, onTab }) {
  return (
    <div className="ps-screen">
      <PSStatusBar/>

      {/* Title bar */}
      <div style={{
        padding: '4px 12px 10px',
        display: 'flex', alignItems: 'center', gap: 8,
        borderBottom: '2px solid var(--duo-swan)',
        background: '#fff',
      }}>
        <button onClick={onBack} className="ps-btn ps-btn--ghost ps-btn--sm ps-btn--icon">
          <PSIcons.ArrowLeft size={18} color="var(--duo-wolf)"/>
        </button>
        <div className="ps-grow">
          <div className="ps-cap" style={{ fontSize: 9, color: 'var(--duo-hare)' }}>HELP · 도움말</div>
          <div style={{ fontFamily: 'var(--font-display)', fontWeight: 900, fontSize: 17, color: 'var(--duo-eel-2)', lineHeight: 1.1 }}>
            How to Play
          </div>
        </div>
        <div style={{ width: 36 }}/>
      </div>

      <div className="ps-tabs" style={{ borderBottom: 'none', padding: '8px 12px 4px' }}>
        <button className="ps-tab" onClick={() => onTab?.('items')}>ITEMS</button>
        <button className="ps-tab active">HOW TO PLAY</button>
        <button className="ps-tab" onClick={() => onTab?.('design')}>DESIGN</button>
      </div>

      <div style={{ flex: 1, overflow: 'auto', padding: '12px 14px 16px', background: 'var(--duo-snow)' }}>

        {/* Hero — what is PlaySpot */}
        <div style={{
          background: 'linear-gradient(180deg, #FFE7CE 0%, #fff 100%)',
          border: '2px solid var(--duo-swan-2)',
          borderRadius: 18,
          boxShadow: '0 3px 0 0 var(--duo-swan-2)',
          padding: '16px 14px',
          marginBottom: 14, position: 'relative',
        }}>
          <div className="ps-cap" style={{ fontSize: 10, color: 'var(--duo-fox)' }}>
            WHAT IS · 플레이스팟이란?
          </div>
          <div className="ps-display" style={{ fontSize: 26, color: 'var(--duo-eel-2)', marginTop: 2 }}>
            PlaySpot?
          </div>
          <div style={{ fontSize: 13, color: 'var(--duo-wolf-2)', marginTop: 6, lineHeight: 1.5 }}>
            지도에 나타난 아이템의 위치를 찾아다니며
            <b style={{ color: 'var(--duo-eel-2)' }}> 미션을 완수</b>하는 게임이에요.
            <br/>경말로 직접 가야 미션을 완수할 수 있어요!
          </div>
          <div style={{ position: 'absolute', right: 8, top: 8 }}>
            <FoxMascot size={56} pose="wave"/>
          </div>
        </div>

        {/* Modes */}
        <SectionLabel kicker="PlaySpot Mode" title="2가지 플레이 모드"/>
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10, marginBottom: 14 }}>
          <ModeCard tint="green" badge="LIVE" name="리얼 모드" desc="미션 생성 장소에서 직접 플레이"/>
          <ModeCard tint="purple" badge="HOME" name="가상 모드" desc="장소 이외에도 현재 위치 기준으로"/>
        </div>

        {/* How to play steps */}
        <SectionLabel kicker="How to Play" title="이렇게 플레이해요"/>
        <div className="ps-col" style={{ gap: 10, marginBottom: 14 }}>
          <PlayStep n={1} title="지도에서 아이템 위치 확인"
            body="필수 아이템 ★ 을 찾아 동선을 짜요."
            visual={<MiniMapVisual/>}/>
          <PlayStep n={2} title="실제로 그 위치로 이동"
            body="목적지 근처에 도착하면 카메라가 활성화돼요."
            visual={<WalkVisual/>}/>
          <PlayStep n={3} title="AR로 아이템 발견 → Shake!"
            body="화면에 PlaySpot 글자가 보이면 탭하거나 흔들어 획득해요."
            visual={<ARShakeVisual/>}/>
          <PlayStep n={4} title="모든 필수 아이템 + End 획득"
            body="모두 모으면 미션 Clear! 뱃지를 받아요."
            visual={<ClearVisual/>}/>
        </div>

        {/* Rewards */}
        <div style={{
          background: 'var(--duo-eel-2)', borderRadius: 16,
          padding: '14px 14px 16px', position: 'relative',
          boxShadow: '0 3px 0 0 #1a1d22',
        }}>
          <div className="ps-cap" style={{ fontSize: 10, color: 'var(--duo-bee)' }}>
            REWARDS · 보상
          </div>
          <div className="ps-display" style={{ fontSize: 18, color: '#fff', marginTop: 2 }}>
            클리어하면 받아요
          </div>
          <div style={{ display: 'flex', gap: 8, marginTop: 10, flexWrap: 'wrap' }}>
            <PerkChip icon={<PSIcons.Bolt size={16}/>}  label="+50 XP" tint="#FFC800"/>
            <PerkChip icon={<PSIcons.Gem size={16}/>}   label="+5 Gems" tint="#CE82FF"/>
            <PerkChip icon={<PSIcons.Flame size={16}/>} label="Streak +1" tint="#FF9600"/>
            <PerkChip icon={<PSIcons.Trophy size={16}/>} label="Badge" tint="#FFC800"/>
          </div>
        </div>

        {/* Bottom helper */}
        <div style={{
          display: 'flex', alignItems: 'flex-end', gap: 8, marginTop: 16,
        }}>
          <FoxMascot size={56} pose="cheer"/>
          <div className="ps-bubble" style={{
            flex: 1, fontSize: 13, position: 'relative',
            background: 'var(--duo-green-100)',
            borderColor: 'var(--duo-green-800)',
            boxShadow: '0 2px 0 0 var(--duo-green-800)',
            color: 'var(--duo-green-900)',
          }}>
            준비됐어요? 첫 미션부터 도전해 봐요!
            <span style={{
              position: 'absolute', left: -10, bottom: 14,
              width: 14, height: 14, background: 'var(--duo-green-100)',
              borderLeft: '2px solid var(--duo-green-800)',
              borderBottom: '2px solid var(--duo-green-800)',
              transform: 'rotate(45deg)',
            }}/>
          </div>
        </div>
      </div>

      {/* Bottom nav */}
      <div className="ps-nav">
        {[
          { id: 'list', icon: <PSIcons.List size={22}/>, label: 'LIST' },
          { id: 'info', icon: <PSIcons.User size={22}/>, label: 'ME' },
          { id: 'badge', icon: <PSIcons.Badge size={22}/>, label: 'BADGES' },
          { id: 'design', icon: <PSIcons.Pencil size={22}/>, label: 'DESIGN' },
          { id: 'help', icon: <PSIcons.Help size={22}/>, label: 'HELP', active: true },
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

function SectionLabel({ kicker, title }) {
  return (
    <div style={{ marginBottom: 8 }}>
      <div className="ps-cap" style={{ fontSize: 10, color: 'var(--duo-macaw)' }}>
        {kicker}
      </div>
      <div style={{ fontFamily: 'var(--font-display)', fontWeight: 900, fontSize: 16, color: 'var(--duo-eel-2)' }}>
        {title}
      </div>
    </div>
  );
}

function ModeCard({ tint, badge, name, desc }) {
  const colors = {
    green:  { fill: 'var(--duo-green-100)', deep: 'var(--duo-green-800)', text: 'var(--duo-green-900)' },
    purple: { fill: '#eed4ff',  deep: 'var(--duo-beetle-deep)', text: 'var(--duo-beetle-deep)' },
  }[tint];
  return (
    <div style={{
      background: colors.fill, border: `2px solid ${colors.deep}`,
      borderRadius: 14, boxShadow: `0 3px 0 0 ${colors.deep}`,
      padding: 12, minHeight: 96,
    }}>
      <div className="ps-chip" style={{
        background: colors.deep, color: '#fff', height: 20, fontSize: 9,
      }}>{badge}</div>
      <div style={{
        fontFamily: 'var(--font-display)', fontWeight: 900,
        fontSize: 15, color: colors.text, marginTop: 6,
      }}>{name}</div>
      <div style={{ fontSize: 11, color: 'var(--duo-wolf-2)', marginTop: 3, lineHeight: 1.35 }}>
        {desc}
      </div>
    </div>
  );
}

function PlayStep({ n, title, body, visual }) {
  return (
    <div style={{
      background: '#fff', border: '2px solid var(--duo-swan-2)',
      borderRadius: 14, boxShadow: '0 2px 0 0 var(--duo-swan-2)',
      padding: 10, display: 'flex', alignItems: 'center', gap: 10,
    }}>
      <div style={{ flex: 'none', width: 70, height: 64,
        background: 'var(--duo-snow)', borderRadius: 10,
        border: '1px solid var(--duo-swan)', overflow: 'hidden',
        position: 'relative',
      }}>{visual}</div>
      <div style={{ flex: 1 }}>
        <div className="ps-row" style={{ gap: 6, alignItems: 'center' }}>
          <div style={{
            width: 20, height: 20, borderRadius: '50%',
            background: 'var(--duo-fox)', color: '#fff',
            fontFamily: 'var(--font-display)', fontWeight: 900, fontSize: 11,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            boxShadow: '0 1px 0 0 var(--duo-fox-deep)',
          }}>{n}</div>
          <div style={{
            fontFamily: 'var(--font-display)', fontWeight: 900,
            fontSize: 13, color: 'var(--duo-eel-2)',
          }}>{title}</div>
        </div>
        <div style={{ fontSize: 11.5, color: 'var(--duo-wolf-2)', marginTop: 4, lineHeight: 1.4 }}>
          {body}
        </div>
      </div>
    </div>
  );
}

function MiniMapVisual() {
  return (
    <svg width="100%" height="100%" viewBox="0 0 70 64" preserveAspectRatio="none">
      <rect width="70" height="64" fill="#dfead0"/>
      <path d="M0 25 Q40 20 70 30" stroke="#fff" strokeWidth="5" fill="none"/>
      <path d="M0 50 Q35 45 70 50" stroke="#fff" strokeWidth="4" fill="none"/>
      <circle cx="22" cy="40" r="3" fill="#FF4B4B"/>
      <circle cx="50" cy="20" r="3" fill="#1CB0F6"/>
      <circle cx="45" cy="48" r="3" fill="#FF9600"/>
    </svg>
  );
}

function WalkVisual() {
  return (
    <svg width="100%" height="100%" viewBox="0 0 70 64" preserveAspectRatio="none">
      <rect width="70" height="64" fill="#bfdfff"/>
      <rect x="0" y="40" width="70" height="24" fill="#5a4a2a"/>
      {/* fox walking */}
      <ellipse cx="20" cy="38" rx="8" ry="6" fill="#FF9600"/>
      <circle cx="14" cy="32" r="5" fill="#FF9600"/>
      <path d="M10 30 L9 24 L13 27 Z" fill="#FF9600"/>
      <path d="M18 30 L19 24 L15 27 Z" fill="#FF9600"/>
      {/* path dots to target */}
      <circle cx="35" cy="36" r="1.5" fill="#fff"/>
      <circle cx="42" cy="34" r="1.5" fill="#fff"/>
      <circle cx="49" cy="32" r="1.5" fill="#fff"/>
      {/* target pin */}
      <circle cx="56" cy="28" r="4" fill="#FF4B4B" stroke="#2D3339" strokeWidth="1.2"/>
    </svg>
  );
}

function ARShakeVisual() {
  return (
    <svg width="100%" height="100%" viewBox="0 0 70 64" preserveAspectRatio="none">
      <defs>
        <radialGradient id="ar1" cx="50%" cy="60%">
          <stop offset="0%" stopColor="#5a8a40"/>
          <stop offset="100%" stopColor="#1d2810"/>
        </radialGradient>
      </defs>
      <rect width="70" height="64" fill="url(#ar1)"/>
      <text x="35" y="34" fontFamily="var(--font-display)" fontWeight="900" fontSize="13"
        fill="#FFC800" textAnchor="middle">PLAY</text>
      <text x="35" y="48" fontFamily="var(--font-display)" fontWeight="900" fontSize="13"
        fill="#FFC800" textAnchor="middle">SPOT</text>
      {/* shake lines */}
      <path d="M8 14 L14 18" stroke="#fff" strokeWidth="1.5" strokeLinecap="round"/>
      <path d="M62 14 L56 18" stroke="#fff" strokeWidth="1.5" strokeLinecap="round"/>
      <path d="M5 24 L11 24" stroke="#fff" strokeWidth="1.5" strokeLinecap="round"/>
    </svg>
  );
}

function ClearVisual() {
  return (
    <svg width="100%" height="100%" viewBox="0 0 70 64" preserveAspectRatio="none">
      <rect width="70" height="64" fill="#fff5d8"/>
      {/* trophy */}
      <path d="M22 18 L48 18 L46 30 Q46 36 35 36 Q24 36 24 30 Z" fill="#FFC800" stroke="#A37800" strokeWidth="1.5"/>
      <rect x="30" y="38" width="10" height="6" fill="#A37800"/>
      <rect x="26" y="44" width="18" height="4" fill="#A37800"/>
      <text x="35" y="55" fontFamily="var(--font-display)" fontWeight="900" fontSize="9"
        fill="#A37800" textAnchor="middle">CLEAR!</text>
      {/* sparkles */}
      <circle cx="10" cy="14" r="1.5" fill="#FF9600"/>
      <circle cx="60" cy="12" r="1.5" fill="#FF9600"/>
      <circle cx="58" cy="32" r="1.5" fill="#CE82FF"/>
    </svg>
  );
}

function PerkChip({ icon, label, tint }) {
  return (
    <div style={{
      display: 'flex', alignItems: 'center', gap: 4,
      background: 'rgba(255,255,255,0.08)',
      border: '1.5px solid rgba(255,255,255,0.15)',
      borderRadius: 999, padding: '4px 10px',
    }}>
      {icon}
      <span style={{
        fontFamily: 'var(--font-display)', fontWeight: 900,
        fontSize: 12, color: tint,
      }}>{label}</span>
    </div>
  );
}


// ─────────────────────────────────────────────────────────────
// SCREEN: Mission Design — 5-step guide to building a mission
// ─────────────────────────────────────────────────────────────
function ScreenDesignGuide({ onBack, onNav, onTab, onStartDesign }) {
  return (
    <div className="ps-screen">
      <PSStatusBar/>

      {/* Title bar */}
      <div style={{
        padding: '4px 12px 10px',
        display: 'flex', alignItems: 'center', gap: 8,
        borderBottom: '2px solid var(--duo-swan)',
        background: '#fff',
      }}>
        <button onClick={onBack} className="ps-btn ps-btn--ghost ps-btn--sm ps-btn--icon">
          <PSIcons.ArrowLeft size={18} color="var(--duo-wolf)"/>
        </button>
        <div className="ps-grow">
          <div className="ps-cap" style={{ fontSize: 9, color: 'var(--duo-hare)' }}>HELP · 도움말</div>
          <div style={{ fontFamily: 'var(--font-display)', fontWeight: 900, fontSize: 17, color: 'var(--duo-eel-2)', lineHeight: 1.1 }}>
            Mission Design
          </div>
        </div>
        <div style={{ width: 36 }}/>
      </div>

      <div className="ps-tabs" style={{ borderBottom: 'none', padding: '8px 12px 4px' }}>
        <button className="ps-tab" onClick={() => onTab?.('items')}>ITEMS</button>
        <button className="ps-tab" onClick={() => onTab?.('howto')}>HOW TO PLAY</button>
        <button className="ps-tab active">DESIGN</button>
      </div>

      <div style={{ flex: 1, overflow: 'auto', padding: '12px 14px 16px', background: 'var(--duo-snow)' }}>

        {/* Hero */}
        <div style={{
          background: 'linear-gradient(180deg, #eed4ff 0%, #fff 100%)',
          border: '2px solid var(--duo-swan-2)',
          borderRadius: 18,
          boxShadow: '0 3px 0 0 var(--duo-swan-2)',
          padding: '14px 14px',
          marginBottom: 14, position: 'relative',
        }}>
          <div className="ps-cap" style={{ fontSize: 10, color: 'var(--duo-beetle-deep)' }}>
            CREATE A MISSION
          </div>
          <div className="ps-display" style={{ fontSize: 22, color: 'var(--duo-eel-2)', marginTop: 2 }}>
            나만의 미션 만들기
          </div>
          <div style={{ fontSize: 12, color: 'var(--duo-wolf-2)', marginTop: 6, lineHeight: 1.5, paddingRight: 60 }}>
            이런 멋진 곳은 같이 봤으면 좋겠는데! 그래서 회원들이
            <b style={{ color: 'var(--duo-eel-2)' }}> 직접 미션을 올릴 수 있어요</b>.
          </div>
          <div style={{ position: 'absolute', right: 6, top: 6 }}>
            <FoxMascot size={56} pose="think"/>
          </div>
        </div>

        {/* 5 design steps */}
        <DesignStep n={1} title="지도에 아이템 배치"
          body="꾹 누르고 드래그하면 아이템이 이동해요."
          tint="green"
          right={<MiniDesignMap/>}/>
        <DesignStep n={2} title="아이템 세부 설정"
          body="탭하면 세부 설정 패널이 열려요. 퀴즈 문제와 정답을 적어요."
          tint="blue"
          right={<MiniQuizForm/>}/>
        <DesignStep n={3} title="미션 정보 입력"
          body="제목 · 설명 · 제한 시간 · 미션 퀴즈를 적어주세요."
          tint="orange"
          right={<MiniMissionForm/>}/>
        <DesignStep n={4} title="직접 테스트"
          body="만든 미션을 본인이 먼저 플레이해 봐요. 가볍게 통과될까?"
          tint="purple"
          right={<MiniTestPhone/>}/>
        <DesignStep n={5} title="업로드 — 단 한 번!"
          body="서버에 올리면 친구들과 즐길 수 있어요. 업로드는 딱 한 번만 가능, 수정 불가!"
          tint="red"
          right={<MiniUpload/>}/>

        {/* CTA */}
        <button onClick={onStartDesign} className="ps-btn ps-btn--purple" style={{
          width: '100%', marginTop: 6, height: 56, fontSize: 15,
        }}>
          <PSIcons.Pencil size={18} color="#fff"/> 미션 만들기 시작!
        </button>
      </div>

      <div className="ps-nav">
        {[
          { id: 'list', icon: <PSIcons.List size={22}/>, label: 'LIST' },
          { id: 'info', icon: <PSIcons.User size={22}/>, label: 'ME' },
          { id: 'badge', icon: <PSIcons.Badge size={22}/>, label: 'BADGES' },
          { id: 'design', icon: <PSIcons.Pencil size={22}/>, label: 'DESIGN' },
          { id: 'help', icon: <PSIcons.Help size={22}/>, label: 'HELP', active: true },
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

function DesignStep({ n, title, body, tint, right }) {
  const colors = {
    green:  { deep: 'var(--duo-green-700)', tint: 'var(--duo-green-500)' },
    blue:   { deep: '#0084c2', tint: 'var(--duo-macaw)' },
    orange: { deep: 'var(--duo-fox-deep)', tint: 'var(--duo-fox)' },
    purple: { deep: 'var(--duo-beetle-deep)', tint: 'var(--duo-beetle)' },
    red:    { deep: '#C12626', tint: 'var(--duo-cardinal)' },
  }[tint];

  return (
    <div style={{
      background: '#fff', border: '2px solid var(--duo-swan-2)',
      borderRadius: 14, boxShadow: '0 2px 0 0 var(--duo-swan-2)',
      padding: 12, marginBottom: 12, display: 'flex', gap: 10,
    }}>
      <div style={{
        flex: 'none', width: 36, height: 36, borderRadius: '50%',
        background: colors.tint, color: '#fff',
        fontFamily: 'var(--font-display)', fontWeight: 900, fontSize: 18,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        boxShadow: `0 2px 0 0 ${colors.deep}`,
        border: '2px solid #fff',
        outline: `2px solid ${colors.deep}`,
      }}>{n}</div>
      <div style={{ flex: 1 }}>
        <div style={{
          fontFamily: 'var(--font-display)', fontWeight: 900,
          fontSize: 14, color: 'var(--duo-eel-2)',
        }}>{title}</div>
        <div style={{
          fontSize: 12, color: 'var(--duo-wolf-2)', marginTop: 4, lineHeight: 1.4,
        }}>{body}</div>
      </div>
      {right && (
        <div style={{
          flex: 'none', width: 80, height: 80, borderRadius: 10,
          background: 'var(--duo-snow)', border: '1px solid var(--duo-swan)',
          overflow: 'hidden', position: 'relative',
        }}>{right}</div>
      )}
    </div>
  );
}

function MiniDesignMap() {
  return (
    <svg width="100%" height="100%" viewBox="0 0 80 80" preserveAspectRatio="none">
      <rect width="80" height="80" fill="#c9d9ad"/>
      <path d="M0 30 Q40 20 80 30" stroke="#fff" strokeWidth="6" fill="none"/>
      <path d="M0 60 Q40 55 80 60" stroke="#fff" strokeWidth="5" fill="none"/>
      <circle cx="25" cy="40" r="4" fill="#FF4B4B" stroke="#2D3339" strokeWidth="1"/>
      <circle cx="55" cy="32" r="4" fill="#1CB0F6" stroke="#2D3339" strokeWidth="1"/>
      <circle cx="40" cy="65" r="4" fill="#58CC02" stroke="#2D3339" strokeWidth="1"/>
      {/* drag hand */}
      <g transform="translate(46 42)">
        <path d="M0 0 L0 -10 L3 -10 L3 0 L8 0 L10 3 L10 12 L-2 12 L-2 0 Z"
          fill="#FF9600" stroke="#2D3339" strokeWidth="1"/>
      </g>
    </svg>
  );
}

function MiniQuizForm() {
  return (
    <div style={{ padding: 6, fontSize: 7, fontFamily: 'var(--font-body)', color: '#2D3339' }}>
      <div style={{ background: '#FF4B4B', color: '#fff', padding: '1px 3px', borderRadius: 3, fontWeight: 800, marginBottom: 3 }}>QUIZ</div>
      <div style={{ background: '#fff', border: '1px solid #ddd', borderRadius: 3, padding: 2, marginBottom: 2 }}>
        Q · 퀴즈 문제를 적으세요
      </div>
      <div style={{ background: '#fff', border: '1px solid #ddd', borderRadius: 3, padding: 2, marginBottom: 2 }}>
        A · 정답
      </div>
      <div style={{ background: '#1CB0F6', color: '#fff', padding: '1px 3px', borderRadius: 3, fontWeight: 800, textAlign: 'center' }}>저장</div>
    </div>
  );
}

function MiniMissionForm() {
  return (
    <div style={{ padding: 6, fontSize: 7, fontFamily: 'var(--font-body)', color: '#2D3339' }}>
      <div style={{ fontWeight: 800, marginBottom: 2 }}>미션 뱃지 설정</div>
      <div style={{ background: '#fff', border: '1px solid #ddd', borderRadius: 3, padding: 2, marginBottom: 2 }}>제목</div>
      <div style={{ background: '#fff', border: '1px solid #ddd', borderRadius: 3, padding: 2, marginBottom: 2 }}>장소</div>
      <div style={{ background: '#fff', border: '1px solid #ddd', borderRadius: 3, padding: 2 }}>설명</div>
    </div>
  );
}

function MiniTestPhone() {
  return (
    <div style={{
      width: '100%', height: '100%',
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      background: 'linear-gradient(180deg, #d8e6c6 0%, #ffe9d2 100%)',
    }}>
      <div style={{
        width: 40, height: 64, background: '#1a1d22',
        borderRadius: 6, padding: 3,
      }}>
        <div style={{
          width: '100%', height: '100%', background: '#FFE9D2',
          borderRadius: 2, display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}>
          <FoxMascot size={24} pose="cheer"/>
        </div>
      </div>
    </div>
  );
}

function MiniUpload() {
  return (
    <svg width="100%" height="100%" viewBox="0 0 80 80" preserveAspectRatio="none">
      <rect width="80" height="80" fill="#fff"/>
      <circle cx="40" cy="35" r="18" fill="#FFE7CE" stroke="#FF9600" strokeWidth="2"/>
      <path d="M40 26 L40 44 M32 34 L40 26 L48 34" stroke="#FF4B4B" strokeWidth="3" fill="none" strokeLinecap="round" strokeLinejoin="round"/>
      <rect x="22" y="55" width="36" height="18" rx="3" fill="#58CC02" stroke="#2D3339" strokeWidth="1.5"/>
      <text x="40" y="67" fontFamily="var(--font-display)" fontWeight="900" fontSize="9"
        fill="#fff" textAnchor="middle">UPLOAD</text>
    </svg>
  );
}

Object.assign(window, {
  ScreenItemGlossary, ScreenHowToPlay, ScreenDesignGuide,
});
