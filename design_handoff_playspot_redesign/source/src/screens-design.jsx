// PlaySpot — Mission Design flow screens
// Redesigned from legacy screenshots:
//   • Design tab list of user's missions (Edit / +)
//   • Modify / Test / Upload action sheet (tap a design row)
//   • More Information (test-play preview) + Virtual/Real mode start sheet
//   • Mission Settings form (badge, title, description, place, quiz, time)
//   • Item Detail (per-item type: Hint, Quiz, Run End, Mine, …)
//   • Item Picker drum (3-column: Item / Display / Visible Range)

// ─────────────────────────────────────────────────────────────
// SCREEN: Mission Design List — list of designs the user has created
// ─────────────────────────────────────────────────────────────
function ScreenDesignList({ onBack, onNew, onPick, onNav }) {
  const designs = [
    { title: 'Level 2 Run!!', desc: '당신은 제한시간까지 뛰어야합니다',
      loc: '동작구 상도1동', date: '2012-07-31 14:15:25',
      tint: 'orange', uploaded: false, badge: <PSIcons.Bolt size={28}/> },
    { title: '서울대 종합', desc: '봉천동 서울대학교 종합 미션',
      loc: '봉천동 서울대학교', date: '2012-07-17 00:28:10',
      tint: 'green', uploaded: true, badge: <PSIcons.Star size={28} color="#FFC800"/> },
    { title: '서울대 암흑 종합', desc: '관악구 낙성대동 — 어두운 골목',
      loc: '관악구 낙성대동', date: '2012-07-17 00:28:10',
      tint: 'purple', uploaded: false, badge: <PSIcons.Gem size={28}/> },
    { title: 'Basic mission', desc: 'run, mine combination',
      loc: 'San 4-10 Nakseongdae-dong, Gwanak-gu',
      date: '2012-07-31 15:25:37',
      tint: 'blue', uploaded: true, badge: <PSIcons.Trophy size={28}/> },
  ];

  return (
    <div className="ps-screen">
      <PSStatusBar/>

      {/* Header */}
      <div style={{
        padding: '8px 12px 12px',
        display: 'flex', alignItems: 'center', gap: 8,
      }}>
        <button onClick={onBack} className="ps-btn ps-btn--ghost ps-btn--sm" style={{ width: 56 }}>EDIT</button>
        <div className="ps-grow" style={{ textAlign: 'center' }}>
          <div className="ps-cap" style={{ fontSize: 9, color: 'var(--duo-hare)' }}>YOUR DESIGNS</div>
          <div style={{ fontFamily: 'var(--font-display)', fontWeight: 900, fontSize: 18, color: 'var(--duo-eel-2)', lineHeight: 1.1 }}>
            Mission Design
          </div>
        </div>
        <button onClick={onNew} className="ps-btn ps-btn--primary ps-btn--sm ps-btn--icon">
          <PSIcons.Plus size={20} color="#fff"/>
        </button>
      </div>

      {/* List */}
      <div style={{ flex: 1, overflow: 'auto', padding: '0 12px 8px', background: 'var(--duo-snow)' }}>
        <div className="ps-col" style={{ gap: 10, paddingTop: 4 }}>
          {designs.map((d, i) => <DesignRow key={i} d={d} onClick={() => onPick?.(d)}/>)}
          {/* New mission CTA */}
          <button onClick={onNew} style={{
            width: '100%',
            background: '#fff',
            border: '2px dashed var(--duo-beetle)',
            borderRadius: 14,
            padding: '18px 12px',
            display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 6,
            cursor: 'pointer',
            color: 'var(--duo-beetle-deep)',
          }}>
            <div style={{
              width: 40, height: 40, borderRadius: '50%',
              background: 'var(--duo-beetle)', color: '#fff',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              boxShadow: '0 3px 0 0 var(--duo-beetle-deep)',
            }}><PSIcons.Plus size={20} color="#fff"/></div>
            <div style={{ fontFamily: 'var(--font-display)', fontWeight: 900, fontSize: 13, letterSpacing: '0.05em' }}>
              새 미션 만들기 · NEW MISSION
            </div>
          </button>
        </div>
      </div>

      {/* Bottom nav */}
      <div className="ps-nav">
        {[
          { id: 'list', icon: <PSIcons.List size={22}/>, label: 'LIST' },
          { id: 'info', icon: <PSIcons.User size={22}/>, label: 'ME' },
          { id: 'badge', icon: <PSIcons.Badge size={22}/>, label: 'BADGES' },
          { id: 'design', icon: <PSIcons.Pencil size={22}/>, label: 'DESIGN', active: true },
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

function StatTile({ big, small, tint }) {
  const colors = {
    blue:   { bg: 'var(--duo-macaw-bg)',   bd: 'var(--duo-macaw-border)', fg: 'var(--duo-macaw-deep)' },
    green:  { bg: 'var(--duo-green-100)',  bd: 'var(--duo-green-800)',    fg: 'var(--duo-green-900)' },
    orange: { bg: 'var(--duo-fox-bg)',     bd: 'var(--duo-fox-deep)',     fg: '#a55e00' },
  }[tint];
  return (
    <div style={{
      flex: 1,
      background: colors.bg,
      border: `2px solid ${colors.bd}`,
      borderRadius: 12,
      boxShadow: `0 2px 0 0 ${colors.bd}`,
      padding: '8px 10px',
      textAlign: 'center',
    }}>
      <div style={{ fontFamily: 'var(--font-display)', fontWeight: 900, fontSize: 18, color: colors.fg }}>{big}</div>
      <div className="ps-cap" style={{ fontSize: 9, color: colors.fg }}>{small}</div>
    </div>
  );
}

function DesignRow({ d, onClick }) {
  const tints = {
    green:  { bg: '#dff8c5', deep: '#43A601', mid: '#93e85c' },
    blue:   { bg: '#d2effd', deep: '#0084c2', mid: '#77d0fa' },
    orange: { bg: '#ffe7ce', deep: '#a55e00', mid: '#ffb766' },
    purple: { bg: '#eed4ff', deep: '#8c39c8', mid: '#ce82ff' },
  };
  const t = tints[d.tint] || tints.green;
  return (
    <button onClick={onClick} style={{
      width: '100%', textAlign: 'left',
      background: '#fff',
      border: '2px solid var(--duo-swan-2)',
      borderRadius: 14,
      boxShadow: '0 3px 0 0 var(--duo-swan-2)',
      padding: 10,
      display: 'flex', gap: 10, alignItems: 'center',
      cursor: 'pointer',
    }}>
      {/* Avatar */}
      <div style={{
        width: 56, height: 56, flex: 'none',
        background: t.bg,
        border: `2px solid ${t.mid}`,
        borderRadius: 14,
        boxShadow: `0 2px 0 0 ${t.mid}`,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
      }}>{d.badge}</div>

      {/* Text */}
      <div style={{ flex: 1, minWidth: 0 }}>
        <div className="ps-row" style={{ gap: 6, alignItems: 'baseline', flexWrap: 'wrap' }}>
          <span style={{
            fontFamily: 'var(--font-display)', fontWeight: 900,
            fontSize: 13, color: 'var(--duo-eel-2)',
          }}>{d.title}</span>
        </div>
        <div style={{ fontSize: 11, color: 'var(--duo-wolf-2)', marginTop: 2,
          whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
          {d.desc}
        </div>
        <div style={{ fontSize: 10, color: 'var(--duo-hare)', marginTop: 4 }}>
          <span style={{ color: 'var(--duo-macaw)' }}>📍 {d.loc}</span>
          <span style={{ marginLeft: 6 }}>· {d.date.slice(0, 10)}</span>
        </div>
      </div>

      <div style={{ flex: 'none', color: 'var(--duo-hare)' }}>
        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5">
          <polyline points="9 18 15 12 9 6"/>
        </svg>
      </div>
    </button>
  );
}


// ─────────────────────────────────────────────────────────────
// SCREEN: Design Action Sheet (Modify / Test / Upload)
// Overlay on Design List background
// ─────────────────────────────────────────────────────────────
function ScreenDesignAction({ design, onModify, onTest, onUpload, onCancel, onNav }) {
  return (
    <div className="ps-screen">
      <PSStatusBar/>
      {/* Faded list behind */}
      <div style={{ flex: 1, position: 'relative', overflow: 'hidden', filter: 'blur(0px)' }}>
        <div style={{ opacity: 0.4, pointerEvents: 'none' }}>
          {/* mini header */}
          <div style={{ padding: '8px 12px 12px', display: 'flex', gap: 8 }}>
            <div className="ps-btn ps-btn--ghost ps-btn--sm" style={{ width: 56 }}>EDIT</div>
            <div className="ps-grow" style={{ textAlign: 'center' }}>
              <div className="ps-cap" style={{ fontSize: 9, color: 'var(--duo-hare)' }}>YOUR DESIGNS</div>
              <div style={{ fontFamily: 'var(--font-display)', fontWeight: 900, fontSize: 18 }}>
                Mission Design
              </div>
            </div>
            <div className="ps-btn ps-btn--primary ps-btn--sm ps-btn--icon">
              <PSIcons.Plus size={20} color="#fff"/>
            </div>
          </div>
          <div style={{ padding: '0 12px', display: 'grid', gap: 8 }}>
            <div style={{ height: 64, background: '#fff', borderRadius: 14, border: '2px solid var(--duo-swan-2)' }}/>
            <div style={{ height: 64, background: '#fff', borderRadius: 14, border: '2px solid var(--duo-swan-2)' }}/>
            <div style={{ height: 64, background: '#fff', borderRadius: 14, border: '2px solid var(--duo-swan-2)' }}/>
          </div>
        </div>

        {/* Dim */}
        <div style={{ position: 'absolute', inset: 0, background: 'rgba(20,15,12,0.55)' }}/>

        {/* Modal — bottom action sheet */}
        <div style={{
          position: 'absolute', left: 12, right: 12, bottom: 12,
          background: '#fff',
          border: '2px solid var(--duo-swan-2)',
          borderRadius: 18,
          boxShadow: '0 4px 0 0 var(--duo-swan-2), 0 20px 40px rgba(0,0,0,0.4)',
          padding: 16,
        }}>
          <div className="ps-cap" style={{ fontSize: 10, color: 'var(--duo-fox)', marginBottom: 2 }}>
            DESIGN
          </div>
          <div style={{ fontFamily: 'var(--font-display)', fontWeight: 900, fontSize: 17, color: 'var(--duo-eel-2)' }}>
            {design?.title || 'Basic mission'}
          </div>
          <div style={{ fontSize: 12, color: 'var(--duo-wolf-2)', marginTop: 4, marginBottom: 14, lineHeight: 1.4 }}>
            완성된 디자인을 테스트해본 뒤<br/>
            <b style={{ color: 'var(--duo-eel-2)' }}>서버에 업로드</b>해서 친구들과 공유해요.
          </div>

          <div className="ps-col" style={{ gap: 8 }}>
            <ActionRow icon={<PSIcons.Pencil size={20} color="#fff"/>}
              tint="blue" title="Modify" subtitle="아이템 위치, 설정을 수정"
              onClick={onModify}/>
            <ActionRow icon={<PSIcons.Compass size={20} color="#fff"/>}
              tint="orange" title="Test Play" subtitle="혼자 먼저 플레이해 보기"
              onClick={onTest}/>
            <ActionRow icon={<PSIcons.Share size={20} color="#fff"/>}
              tint="green" title="Server Upload" subtitle="딱 한 번 — 업로드 후 수정 불가"
              onClick={onUpload} important/>
          </div>

          <button onClick={onCancel} className="ps-btn ps-btn--ghost" style={{ width: '100%', marginTop: 12 }}>
            CANCEL
          </button>
        </div>
      </div>

      {/* Bottom nav peeks through */}
      <div className="ps-nav">
        {[
          { id: 'list', icon: <PSIcons.List size={22}/>, label: 'LIST' },
          { id: 'info', icon: <PSIcons.User size={22}/>, label: 'ME' },
          { id: 'badge', icon: <PSIcons.Badge size={22}/>, label: 'BADGES' },
          { id: 'design', icon: <PSIcons.Pencil size={22}/>, label: 'DESIGN', active: true },
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

function PSIcon_Compass(p) {
  const { size = 20, color = "#fff" } = p;
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={color} strokeWidth="2.5" strokeLinejoin="round">
      <circle cx="12" cy="12" r="9"/><polygon points="16 8 13 13 8 16 11 11 16 8" fill={color}/>
    </svg>
  );
}

function ActionRow({ icon, tint, title, subtitle, onClick, important }) {
  const colors = {
    blue:   { bg: 'var(--duo-macaw)',     deep: '#0084c2' },
    orange: { bg: 'var(--duo-fox)',       deep: 'var(--duo-fox-deep)' },
    green:  { bg: 'var(--duo-green-500)', deep: 'var(--duo-green-700)' },
  }[tint];
  return (
    <button onClick={onClick} style={{
      width: '100%', textAlign: 'left',
      background: '#fff',
      border: `2px solid ${important ? colors.bg : 'var(--duo-swan-2)'}`,
      borderRadius: 12,
      boxShadow: `0 2px 0 0 ${important ? colors.deep : 'var(--duo-swan-2)'}`,
      padding: 10,
      display: 'flex', gap: 10, alignItems: 'center',
      cursor: 'pointer',
    }}>
      <div style={{
        flex: 'none', width: 36, height: 36, borderRadius: 10,
        background: colors.bg, boxShadow: `0 2px 0 0 ${colors.deep}`,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
      }}>{icon}</div>
      <div style={{ flex: 1 }}>
        <div style={{
          fontFamily: 'var(--font-display)', fontWeight: 900,
          fontSize: 14, color: 'var(--duo-eel-2)',
        }}>{title}</div>
        <div style={{ fontSize: 11, color: 'var(--duo-wolf-2)', marginTop: 1 }}>
          {subtitle}
        </div>
      </div>
      <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="var(--duo-hare)" strokeWidth="2.5">
        <polyline points="9 18 15 12 9 6"/>
      </svg>
    </button>
  );
}


// ─────────────────────────────────────────────────────────────
// SCREEN: Mission More Information (test-play preview)
// ─────────────────────────────────────────────────────────────
function ScreenMissionInfo({ design, onBack, onPlay, onNav, showStartSheet }) {
  return (
    <div className="ps-screen">
      <PSStatusBar/>

      {/* Header */}
      <div style={{
        padding: '4px 12px 10px',
        display: 'flex', alignItems: 'center', gap: 8,
        borderBottom: '2px solid var(--duo-swan)',
        background: '#fff',
      }}>
        <button onClick={onBack} className="ps-btn ps-btn--ghost ps-btn--sm" style={{ width: 56 }}>목록</button>
        <div className="ps-grow" style={{ textAlign: 'center' }}>
          <div className="ps-cap" style={{ fontSize: 9, color: 'var(--duo-hare)' }}>MISSION INFO</div>
          <div style={{ fontFamily: 'var(--font-display)', fontWeight: 900, fontSize: 16, color: 'var(--duo-eel-2)', lineHeight: 1.1 }}>
            More Information
          </div>
        </div>
        <button onClick={onPlay} className="ps-btn ps-btn--primary ps-btn--sm" style={{ width: 56 }}>PLAY</button>
      </div>

      {/* Scroll body */}
      <div style={{ flex: 1, overflow: 'auto', padding: '12px 14px 16px', background: 'var(--duo-snow)', position: 'relative' }}>

        {/* Mission hero card */}
        <div style={{
          background: '#fff', border: '2px solid var(--duo-swan-2)',
          borderRadius: 18, boxShadow: '0 3px 0 0 var(--duo-swan-2)',
          padding: 12, marginBottom: 12,
          display: 'flex', gap: 12, alignItems: 'center',
        }}>
          <div style={{
            width: 64, height: 64, flex: 'none',
            background: '#d2effd', border: '2px solid var(--duo-macaw-border)',
            borderRadius: 14, boxShadow: '0 2px 0 0 var(--duo-macaw-border)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
          }}>
            <PSIcons.Trophy size={32}/>
          </div>
          <div style={{ flex: 1, minWidth: 0 }}>
            <div className="ps-cap" style={{ fontSize: 9, color: 'var(--duo-macaw)' }}>BY EJOLA</div>
            <div style={{ fontFamily: 'var(--font-display)', fontWeight: 900, fontSize: 17, color: 'var(--duo-eel-2)', lineHeight: 1.1 }}>
              Basic Mission
            </div>
            <div className="ps-row" style={{ gap: 3, marginTop: 4 }}>
              {Array.from({length: 5}).map((_, i) => <PSIcons.Star key={i} size={12} color={i < 4 ? '#FFC800' : '#e5e5e5'}/>)}
              <span style={{ fontSize: 10, color: 'var(--duo-hare)', marginLeft: 4 }}>4.0 · Play(0) Fail(0)</span>
            </div>
          </div>
        </div>

        {/* Info rows */}
        <InfoRow icon={<PSIcons.Pencil size={16} color="#fff"/>} tint="blue"
          label="Mission Description" value="run, mine combination"/>
        <InfoRow icon={<PSIcons.Map size={16} color="#fff"/>} tint="green"
          label="Mission Place"
          value="San 4-10 Nakseongdae-dong, Gwanak-gu, Seoul, South Korea"/>
        <InfoRow icon={<PSIcons.Target size={16} color="#fff"/>} tint="orange"
          label="Items in Mission" value="Total 6 · Mandatory 4"/>
        <InfoRow icon={<PSIcons.Help size={16} color="#fff"/>} tint="purple"
          label="Mission Quiz" value="(넌센스) 장님도 볼 수 있는 것은?"/>
        <InfoRow icon={<PSIcons.Compass size={16} color="#fff"/>} tint="red"
          label="Time Limit" value="00:05:00"/>
        <InfoRow icon={<PSIcons.Star size={16} color="#fff"/>} tint="blue"
          label="Created" value="2012-07-31"/>

        {/* Inline items preview */}
        <div style={{ marginTop: 12 }}>
          <div className="ps-cap" style={{ fontSize: 10, color: 'var(--duo-hare)', marginBottom: 6 }}>
            ITEMS IN THIS MISSION
          </div>
          <div className="ps-card" style={{
            padding: 10, borderRadius: 14,
            display: 'flex', gap: 6, flexWrap: 'wrap', justifyContent: 'space-around',
          }}>
            {['start', 'end', 'hint', 'quiz', 'mine', 'defence'].map(k => (
              <div key={k} style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 2, width: 50 }}>
                <ItemPin kind={k} size={32}/>
                <span style={{ fontSize: 9, color: 'var(--duo-wolf-2)', fontFamily: 'var(--font-display)', fontWeight: 900 }}>
                  {GAME_ITEMS[k].name}
                </span>
              </div>
            ))}
          </div>
        </div>

        {/* Virtual / Real mode start sheet (overlays on top when showing) */}
        {showStartSheet && (
          <div style={{
            position: 'absolute', inset: 0,
            background: 'rgba(20,15,12,0.55)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            padding: 16,
          }}>
            <div style={{
              width: '100%', maxWidth: 280,
              background: '#fff', border: '2px solid var(--duo-swan-2)',
              borderRadius: 18,
              boxShadow: '0 4px 0 0 var(--duo-swan-2), 0 20px 40px rgba(0,0,0,0.4)',
              padding: 18, textAlign: 'center',
            }}>
              <div style={{ marginBottom: 10, display: 'flex', justifyContent: 'center', gap: 6 }}>
                <Wordmark2 word="PLAY"/>
                <Wordmark2 word="SPOT"/>
              </div>
              <div style={{
                fontSize: 12, color: 'var(--duo-wolf-2)',
                lineHeight: 1.5, marginBottom: 14,
              }}>
                <b style={{ color: 'var(--duo-macaw-deep)' }}>Virtual</b>은 현재 위치 기준,
                <b style={{ color: 'var(--duo-fox-deep)' }}> Real</b>은 미션 생성 장소에서 직접 플레이해요.
              </div>
              <div style={{ display: 'flex', gap: 8, marginBottom: 10 }}>
                <button className="ps-btn ps-btn--blue ps-btn--sm" style={{ flex: 1 }}>Virtual</button>
                <button className="ps-btn ps-btn--orange ps-btn--sm" style={{ flex: 1 }}>Real</button>
              </div>
              <button onClick={onPlay} className="ps-btn ps-btn--primary" style={{ width: '100%' }}>
                MISSION START!
              </button>
            </div>
          </div>
        )}
      </div>

      <div className="ps-nav">
        {[
          { id: 'list', icon: <PSIcons.List size={22}/>, label: 'LIST' },
          { id: 'info', icon: <PSIcons.User size={22}/>, label: 'ME' },
          { id: 'badge', icon: <PSIcons.Badge size={22}/>, label: 'BADGES' },
          { id: 'design', icon: <PSIcons.Pencil size={22}/>, label: 'DESIGN', active: true },
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

function Wordmark2({ word }) {
  return (
    <div style={{
      fontFamily: 'var(--font-display)', fontWeight: 900,
      fontSize: 26, letterSpacing: '0.03em',
      color: 'var(--duo-fox)',
      WebkitTextStroke: '1.5px #2D3339',
      lineHeight: 0.95,
      textShadow: '2px 2px 0 rgba(0,0,0,0.15)',
    }}>{word}</div>
  );
}

function InfoRow({ icon, tint, label, value }) {
  const tints = {
    blue:   { bg: 'var(--duo-macaw)',     deep: '#0084c2' },
    green:  { bg: 'var(--duo-green-500)', deep: 'var(--duo-green-700)' },
    orange: { bg: 'var(--duo-fox)',       deep: 'var(--duo-fox-deep)' },
    purple: { bg: 'var(--duo-beetle)',    deep: 'var(--duo-beetle-deep)' },
    red:    { bg: 'var(--duo-cardinal)',  deep: '#C12626' },
  };
  const t = tints[tint] || tints.blue;
  return (
    <div style={{
      background: '#fff', border: '2px solid var(--duo-swan-2)',
      borderRadius: 12, boxShadow: '0 2px 0 0 var(--duo-swan-2)',
      padding: 10, marginBottom: 8,
      display: 'flex', gap: 10, alignItems: 'center',
    }}>
      <div style={{
        flex: 'none', width: 28, height: 28, borderRadius: 8,
        background: t.bg, boxShadow: `0 1px 0 0 ${t.deep}`,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
      }}>{icon}</div>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div className="ps-cap" style={{ fontSize: 9, color: 'var(--duo-hare)' }}>{label}</div>
        <div style={{ fontSize: 13, color: 'var(--duo-eel-2)', fontWeight: 700,
          marginTop: 1, lineHeight: 1.3,
        }}>{value}</div>
      </div>
    </div>
  );
}


// ─────────────────────────────────────────────────────────────
// SCREEN: Mission Settings — title / description / place / quiz / time
// ─────────────────────────────────────────────────────────────
function ScreenMissionSettings({ onCancel, onSave, onNav }) {
  const [virtual, setVirtual] = React.useState(true);
  return (
    <div className="ps-screen">
      <PSStatusBar/>

      {/* Header */}
      <div style={{
        padding: '4px 12px 10px',
        display: 'flex', alignItems: 'center', gap: 8,
        borderBottom: '2px solid var(--duo-swan)',
        background: '#fff',
      }}>
        <button onClick={onCancel} className="ps-btn ps-btn--ghost ps-btn--sm" style={{ width: 64 }}>CANCEL</button>
        <div className="ps-grow" style={{ textAlign: 'center' }}>
          <div className="ps-cap" style={{ fontSize: 9, color: 'var(--duo-hare)' }}>STEP 3 OF 3</div>
          <div style={{ fontFamily: 'var(--font-display)', fontWeight: 900, fontSize: 16, color: 'var(--duo-eel-2)', lineHeight: 1.1 }}>
            Mission Settings
          </div>
        </div>
        <button onClick={onSave} className="ps-btn ps-btn--primary ps-btn--sm" style={{ width: 64 }}>SAVE</button>
      </div>

      {/* Body */}
      <div style={{ flex: 1, overflow: 'auto', padding: '12px 14px 16px', background: 'var(--duo-snow)' }}>

        {/* Badge picker card */}
        <div style={{
          background: 'linear-gradient(180deg, var(--duo-green-100) 0%, #fff 60%)',
          border: '2px solid var(--duo-green-800)',
          borderRadius: 18,
          boxShadow: '0 3px 0 0 var(--duo-green-800)',
          padding: 14, marginBottom: 14,
          display: 'flex', gap: 12, alignItems: 'center',
        }}>
          <div style={{ flex: 1 }}>
            <div className="ps-cap" style={{ fontSize: 10, color: 'var(--duo-green-800)' }}>
              미션 뱃지 설정
            </div>
            <div style={{ fontFamily: 'var(--font-display)', fontWeight: 900, fontSize: 14, color: 'var(--duo-eel-2)', marginTop: 2 }}>
              MISSION BADGE
            </div>
            <div style={{ fontSize: 11, color: 'var(--duo-wolf-2)', marginTop: 2 }}>
              미션 뱃지를 설정하세요.
            </div>
          </div>
          <div style={{
            width: 60, height: 60, borderRadius: 14,
            background: '#fff',
            border: '2px dashed var(--duo-green-800)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            cursor: 'pointer',
          }}>
            <PSIcons.Camera2 size={26} color="var(--duo-green-800)"/>
          </div>
        </div>

        {/* Form fields */}
        <FormField label="미션 제목 · TITLE" placeholder="예: 서울대 지뢰밭"
          icon={<PSIcons.Pencil size={14} color="#fff"/>} tint="blue"/>
        <FormField label="미션 설명 · DESCRIPTION" multiline
          placeholder="run, mine combination — 어떤 미션인지 설명을 적어주세요"
          icon={<PSIcons.List size={14} color="#fff"/>} tint="green"/>
        <FormField label="장소 · PLACE"
          placeholder="San 4-10 Nakseongdae-dong, Gwanak-gu"
          value="San 4-10 Nakseongdae-dong, Gwanak-gu"
          icon={<PSIcons.Map size={14} color="#fff"/>} tint="orange"
          locked/>
        <FormField label="미션 퀴즈 · QUIZ"
          placeholder="(넌센스) 장님도 볼 수 있는 것은?"
          icon={<PSIcons.Help size={14} color="#fff"/>} tint="purple"/>
        <FormField label="정답 · ANSWER"
          placeholder="Write the correct answer to your quiz"
          icon={<PSIcons.Target size={14} color="#fff"/>} tint="red"/>

        {/* Virtual Mode banner */}
        <div style={{
          background: virtual ? 'var(--duo-macaw-bg)' : 'var(--duo-fox-bg)',
          border: `2px solid ${virtual ? 'var(--duo-macaw-border)' : 'var(--duo-fox-deep)'}`,
          borderRadius: 14,
          boxShadow: `0 2px 0 0 ${virtual ? 'var(--duo-macaw-border)' : 'var(--duo-fox-deep)'}`,
          padding: 12, marginTop: 4,
        }}>
          <div className="ps-row" style={{ justifyContent: 'space-between' }}>
            <div style={{ flex: 1, paddingRight: 10 }}>
              <div style={{ fontFamily: 'var(--font-display)', fontWeight: 900, fontSize: 13, color: 'var(--duo-eel-2)' }}>
                Virtual Mode {virtual ? '· ON' : '· OFF'}
              </div>
              <div style={{ fontSize: 11, color: 'var(--duo-wolf-2)', marginTop: 3, lineHeight: 1.4 }}>
                {virtual
                  ? '현재 위치에서도 플레이 가능. 누구나 어디서든 도전!'
                  : '미션 생성 장소에서만 플레이 가능해요.'}
              </div>
            </div>
            <PSToggle on={virtual} onChange={setVirtual}/>
          </div>
        </div>

        {/* Time limit */}
        <div style={{
          background: '#fff', border: '2px solid var(--duo-swan-2)',
          borderRadius: 14, boxShadow: '0 2px 0 0 var(--duo-swan-2)',
          padding: 12, marginTop: 10,
          display: 'flex', alignItems: 'center', gap: 12,
        }}>
          <div style={{
            flex: 'none', width: 28, height: 28, borderRadius: 8,
            background: 'var(--duo-cardinal)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            boxShadow: '0 1px 0 0 #C12626',
          }}>
            <PSIcons.Compass size={16} color="#fff"/>
          </div>
          <div style={{ flex: 1 }}>
            <div className="ps-cap" style={{ fontSize: 9, color: 'var(--duo-hare)' }}>
              제한 시간 · TIME LIMIT
            </div>
            <div style={{ display: 'flex', gap: 4, marginTop: 4 }}>
              {'00:05:00'.split('').map((c, i) => (
                c === ':' ?
                  <div key={i} style={{
                    fontFamily: 'var(--font-display)', fontWeight: 900, fontSize: 22,
                    color: 'var(--duo-eel-2)',
                  }}>:</div> :
                  <div key={i} className="ps-digit" style={{ width: 22, height: 30, fontSize: 16 }}>{c}</div>
              ))}
            </div>
          </div>
        </div>

      </div>

      <div className="ps-nav">
        {[
          { id: 'list', icon: <PSIcons.List size={22}/>, label: 'LIST' },
          { id: 'info', icon: <PSIcons.User size={22}/>, label: 'ME' },
          { id: 'badge', icon: <PSIcons.Badge size={22}/>, label: 'BADGES' },
          { id: 'design', icon: <PSIcons.Pencil size={22}/>, label: 'DESIGN', active: true },
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

function FormField({ label, placeholder, value, multiline, icon, tint, locked }) {
  const tints = {
    blue:   { deep: '#0084c2',     bg: 'var(--duo-macaw)' },
    green:  { deep: 'var(--duo-green-700)', bg: 'var(--duo-green-500)' },
    orange: { deep: 'var(--duo-fox-deep)',  bg: 'var(--duo-fox)' },
    purple: { deep: 'var(--duo-beetle-deep)', bg: 'var(--duo-beetle)' },
    red:    { deep: '#C12626',  bg: 'var(--duo-cardinal)' },
  };
  const t = tints[tint] || tints.blue;
  return (
    <div style={{
      background: '#fff', border: '2px solid var(--duo-swan-2)',
      borderRadius: 12, boxShadow: '0 2px 0 0 var(--duo-swan-2)',
      padding: 10, marginBottom: 8,
    }}>
      <div className="ps-row" style={{ gap: 8, marginBottom: 6 }}>
        <div style={{
          width: 22, height: 22, borderRadius: 6,
          background: t.bg, boxShadow: `0 1px 0 0 ${t.deep}`,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}>{icon}</div>
        <div className="ps-cap" style={{ fontSize: 10, color: 'var(--duo-wolf-2)' }}>
          {label}
        </div>
        {locked && (
          <span style={{ marginLeft: 'auto', color: 'var(--duo-hare)' }}>
            <svg width="12" height="14" viewBox="0 0 12 14" fill="currentColor">
              <path d="M3 6V4a3 3 0 0 1 6 0v2h1v7H2V6h1zm2 0h2V4a1 1 0 0 0-2 0v2z"/>
            </svg>
          </span>
        )}
      </div>
      <div style={{
        background: locked ? 'var(--duo-snow)' : '#fff',
        border: '1.5px solid var(--duo-swan)',
        borderRadius: 8,
        padding: '6px 10px',
        minHeight: multiline ? 60 : 30,
        fontSize: 13,
        color: value ? 'var(--duo-eel-2)' : 'var(--duo-hare)',
        fontWeight: value ? 700 : 400,
        lineHeight: 1.4,
      }}>
        {value || placeholder}
      </div>
    </div>
  );
}

function PSToggle({ on, onChange }) {
  return (
    <button onClick={() => onChange?.(!on)} style={{
      flex: 'none',
      width: 56, height: 32, borderRadius: 18,
      background: on ? 'var(--duo-green-500)' : '#bbb',
      border: 'none',
      position: 'relative', cursor: 'pointer',
      boxShadow: on ? '0 2px 0 0 var(--duo-green-700)' : '0 2px 0 0 #888',
      transition: 'background 0.15s',
    }}>
      <div style={{
        position: 'absolute', top: 2, left: on ? 26 : 2,
        width: 26, height: 26, borderRadius: '50%',
        background: '#fff',
        boxShadow: '0 1px 2px rgba(0,0,0,0.3)',
        transition: 'left 0.15s',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        fontFamily: 'var(--font-display)', fontWeight: 900, fontSize: 9,
        color: on ? 'var(--duo-green-700)' : '#888',
      }}>{on ? 'ON' : 'OFF'}</div>
    </button>
  );
}


// ─────────────────────────────────────────────────────────────
// SCREEN: Item Detail — per-item-type settings (Hint, Quiz, Run End, Mine)
// ─────────────────────────────────────────────────────────────
function ScreenItemDetail({ kind = 'hint', onDone, onDelete }) {
  const item = GAME_ITEMS[kind] || GAME_ITEMS.hint;
  const [mandatory, setMandatory] = React.useState(item.essential);
  const [range, setRange] = React.useState(30);

  return (
    <div className="ps-screen">
      <PSStatusBar/>

      {/* Header — uses item's body color as accent */}
      <div style={{
        padding: '4px 12px 10px',
        display: 'flex', alignItems: 'center', gap: 8,
        background: '#fff',
        borderBottom: '2px solid var(--duo-swan)',
      }}>
        <button onClick={onDone} className="ps-btn ps-btn--ghost ps-btn--sm" style={{ width: 56 }}>DONE</button>
        <div className="ps-grow" style={{ textAlign: 'center', display: 'flex', alignItems: 'center', gap: 8, justifyContent: 'center' }}>
          <ItemPin kind={kind} size={28}/>
          <div>
            <div className="ps-cap" style={{ fontSize: 9, color: 'var(--duo-hare)' }}>ITEM DETAIL</div>
            <div style={{ fontFamily: 'var(--font-display)', fontWeight: 900, fontSize: 16, color: 'var(--duo-eel-2)', lineHeight: 1.1 }}>
              {item.name}
            </div>
          </div>
        </div>
        <div style={{ width: 56 }}/>
      </div>

      <div style={{ flex: 1, overflow: 'auto', padding: '12px 14px 16px', background: 'var(--duo-snow)' }}>

        {/* Section: basic info */}
        <SectionHeader title="Item Basic Information" subtitle="아이템 기본 정보"/>
        <div className="ps-card" style={{ padding: 0, marginBottom: 14, borderRadius: 14, overflow: 'hidden' }}>
          <DetailRow label="Item Type" sub="아이템 종류"
            value={
              <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                <span style={{
                  fontFamily: 'var(--font-display)', fontWeight: 900,
                  fontSize: 14, color: item.tint,
                }}>{item.name}</span>
              </div>
            }/>
          <DetailRow label="Mandatory?" sub="필수 여부"
            value={<PSToggle on={mandatory} onChange={setMandatory}/>}/>
          <DetailRow label="Display" sub="투명 표시"
            value={
              <div className="ps-row" style={{ gap: 4 }}>
                {['Normal','Hidden','Stealth'].map(opt => {
                  const active = opt === (item.transparency === 'stealth' ? 'Stealth'
                                       : item.transparency === 'hidden'  ? 'Hidden' : 'Normal');
                  return (
                    <div key={opt} style={{
                      padding: '4px 8px', borderRadius: 8,
                      fontFamily: 'var(--font-display)', fontWeight: 900, fontSize: 10,
                      letterSpacing: '0.04em',
                      background: active ? 'var(--duo-macaw)' : '#fff',
                      color: active ? '#fff' : 'var(--duo-wolf-2)',
                      border: `2px solid ${active ? '#0084c2' : 'var(--duo-swan-2)'}`,
                      boxShadow: active ? '0 1px 0 0 #0084c2' : '0 1px 0 0 var(--duo-swan-2)',
                    }}>{opt}</div>
                  );
                })}
              </div>
            }
            isLast/>
        </div>

        {/* Visible Range slider */}
        <SectionHeader title="Visible Range" subtitle="유효 반경 (미터)"/>
        <div className="ps-card" style={{ padding: 14, marginBottom: 14, borderRadius: 14 }}>
          <div className="ps-row" style={{ justifyContent: 'space-between', marginBottom: 8 }}>
            <span style={{ fontSize: 11, color: 'var(--duo-hare)', fontFamily: 'var(--font-display)', fontWeight: 800 }}>10m</span>
            <span style={{
              fontFamily: 'var(--font-display)', fontWeight: 900,
              fontSize: 22, color: item.tint, letterSpacing: '-0.02em',
            }}>{range}<small style={{ fontSize: 12, color: 'var(--duo-wolf-2)' }}> m</small></span>
            <span style={{ fontSize: 11, color: 'var(--duo-hare)', fontFamily: 'var(--font-display)', fontWeight: 800 }}>100m</span>
          </div>
          {/* Custom track */}
          <div style={{ position: 'relative', height: 14 }}>
            <div style={{
              position: 'absolute', inset: 0,
              background: 'var(--duo-swan)', borderRadius: 999,
            }}/>
            <div style={{
              position: 'absolute', top: 0, bottom: 0, left: 0,
              width: `${((range-10)/90)*100}%`,
              background: item.tint, borderRadius: 999,
              boxShadow: `0 -2px 0 0 ${item.deep} inset`,
            }}/>
            <input type="range" min="10" max="100" step="10"
              value={range} onChange={e => setRange(+e.target.value)}
              style={{
                position: 'absolute', inset: -4, width: '100%',
                opacity: 0, cursor: 'pointer',
              }}/>
            <div style={{
              position: 'absolute', top: -4,
              left: `calc(${((range-10)/90)*100}% - 11px)`,
              width: 22, height: 22, borderRadius: '50%',
              background: '#fff', border: `3px solid ${item.tint}`,
              boxShadow: '0 2px 0 0 rgba(0,0,0,0.15)',
            }}/>
          </div>
        </div>

        {/* Per-item additional fields */}
        {kind === 'hint' && <HintExtras/>}
        {kind === 'quiz' && <QuizExtras/>}
        {kind === 'runEnd' && <RunEndExtras/>}
        {kind === 'mine' && <MineExtras/>}

        {/* Delete */}
        <button onClick={onDelete} className="ps-btn ps-btn--red" style={{
          width: '100%', marginTop: 6, height: 52, fontSize: 14,
        }}>
          {item.name} 삭제 · DELETE
        </button>
      </div>
    </div>
  );
}

function SectionHeader({ title, subtitle }) {
  return (
    <div style={{ marginBottom: 6, padding: '0 4px' }}>
      <div className="ps-cap" style={{ fontSize: 9, color: 'var(--duo-hare)' }}>
        {subtitle}
      </div>
      <div style={{ fontFamily: 'var(--font-display)', fontWeight: 900, fontSize: 13, color: 'var(--duo-eel-2)' }}>
        {title}
      </div>
    </div>
  );
}

function DetailRow({ label, sub, value, isLast }) {
  return (
    <div style={{
      display: 'flex', alignItems: 'center', gap: 12,
      padding: '12px 14px',
      borderBottom: isLast ? 'none' : '1px solid var(--duo-swan)',
    }}>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{
          fontFamily: 'var(--font-display)', fontWeight: 900,
          fontSize: 13, color: 'var(--duo-macaw-deep)',
        }}>{label}</div>
        <div style={{ fontSize: 10, color: 'var(--duo-hare)', marginTop: 1 }}>{sub}</div>
      </div>
      <div>{value}</div>
    </div>
  );
}

function HintExtras() {
  return (
    <>
      <SectionHeader title="Item Additional Information" subtitle="추가 정보"/>
      <div className="ps-card" style={{ padding: 12, borderRadius: 14, marginBottom: 14 }}>
        <DetailRow label="Mini-game" sub="힌트 잠금해제 방식"
          value={<span style={{
            fontFamily: 'var(--font-display)', fontWeight: 900, fontSize: 12,
            background: 'var(--duo-snow)', padding: '4px 10px', borderRadius: 8,
            color: 'var(--duo-wolf-2)',
          }}>None ▾</span>} isLast/>
        <div style={{ padding: '8px 0 0' }}>
          <div className="ps-cap" style={{ fontSize: 9, color: 'var(--duo-hare)', marginBottom: 4 }}>
            HINT TEXT · 미션 퀴즈에 대한 힌트
          </div>
          <div style={{
            background: 'var(--duo-snow)',
            border: '1.5px solid var(--duo-swan)',
            borderRadius: 8, padding: '8px 10px',
            minHeight: 60, fontSize: 12, color: 'var(--duo-hare)', lineHeight: 1.4,
          }}>
            Write a hint about Mission Quiz<br/>
            <span style={{ color: 'var(--duo-eel-2)', fontWeight: 700 }}>
              "수수께끼: 눈으로 보지 않고도 볼 수 있는 것"
            </span>
          </div>
        </div>
      </div>
    </>
  );
}

function QuizExtras() {
  return (
    <>
      <SectionHeader title="Item Quiz" subtitle="아이템 퀴즈"/>
      <div className="ps-card" style={{ padding: 12, borderRadius: 14, marginBottom: 12 }}>
        <div className="ps-cap" style={{ fontSize: 9, color: 'var(--duo-hare)', marginBottom: 4 }}>
          QUESTION · 퀴즈 문제를 적으세요
        </div>
        <div style={{
          background: 'var(--duo-snow)',
          border: '1.5px solid var(--duo-swan)',
          borderRadius: 8, padding: '8px 10px',
          fontSize: 12, color: 'var(--duo-eel-2)', fontWeight: 700, marginBottom: 10,
        }}>
          퀴즈 정답을 볼 수 있는 아이템 이름은?
        </div>
        <div className="ps-cap" style={{ fontSize: 9, color: 'var(--duo-hare)', marginBottom: 4 }}>
          ANSWER · 퀴즈 답
        </div>
        <div style={{
          background: 'var(--duo-snow)',
          border: '1.5px solid var(--duo-swan)',
          borderRadius: 8, padding: '8px 10px',
          fontSize: 12, color: 'var(--duo-eel-2)', fontWeight: 700,
        }}>
          Solution
        </div>
        <div style={{ fontSize: 10, color: 'var(--duo-hare)', marginTop: 8, lineHeight: 1.4 }}>
          ⓘ 미션 플레이 시 1 / 추가 횟수 확률로 적용됩니다.
        </div>
      </div>
    </>
  );
}

function RunEndExtras() {
  return (
    <>
      <SectionHeader title="Run Settings" subtitle="러닝 설정"/>
      <div className="ps-card" style={{ padding: 0, borderRadius: 14, marginBottom: 14, overflow: 'hidden' }}>
        <DetailRow label="Distance from Run Start" sub="Run Start와의 거리"
          value={<span style={{ fontFamily: 'var(--font-display)', fontWeight: 900, fontSize: 14, color: 'var(--duo-fox-deep)' }}>63 m</span>}/>
        <DetailRow label="Time Limit" sub="제한 시간"
          value={
            <div style={{ display: 'flex', gap: 3, alignItems: 'center' }}>
              <div className="ps-digit" style={{ width: 20, height: 26, fontSize: 14 }}>0</div>
              <div className="ps-digit" style={{ width: 20, height: 26, fontSize: 14 }}>1</div>
              <span style={{ fontSize: 10, color: 'var(--duo-hare)', fontWeight: 800 }}>min</span>
              <div className="ps-digit" style={{ width: 20, height: 26, fontSize: 14 }}>0</div>
              <div className="ps-digit" style={{ width: 20, height: 26, fontSize: 14 }}>0</div>
              <span style={{ fontSize: 10, color: 'var(--duo-hare)', fontWeight: 800 }}>sec</span>
            </div>
          } isLast/>
      </div>
    </>
  );
}

function MineExtras() {
  return (
    <>
      <SectionHeader title="Blast Properties" subtitle="폭발 속성"/>
      <div className="ps-card" style={{ padding: 12, borderRadius: 14, marginBottom: 14, position: 'relative' }}>
        <div style={{ display: 'flex', gap: 12, alignItems: 'center' }}>
          <div style={{
            width: 70, height: 70, flex: 'none',
            borderRadius: '50%',
            background: 'radial-gradient(circle, rgba(255,75,75,0.5) 0%, rgba(255,75,75,0.15) 70%, transparent 100%)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            border: '2px dashed var(--duo-cardinal)',
          }}>
            <ItemPin kind="mine" size={34}/>
          </div>
          <div style={{ flex: 1 }}>
            <div style={{ fontFamily: 'var(--font-display)', fontWeight: 900, fontSize: 13, color: 'var(--duo-eel-2)' }}>
              피해 반경 · BLAST RADIUS
            </div>
            <div style={{ fontFamily: 'var(--font-display)', fontWeight: 900, fontSize: 20, color: 'var(--duo-cardinal-deep)' }}>
              40 <small style={{ fontSize: 12, color: 'var(--duo-wolf-2)' }}>m</small>
            </div>
            <div style={{ fontSize: 10, color: 'var(--duo-wolf-2)', marginTop: 2, lineHeight: 1.4 }}>
              이 반경 안에 들어오면 마지막으로 획득한 아이템을 잃어요.
            </div>
          </div>
        </div>
      </div>
    </>
  );
}


// ─────────────────────────────────────────────────────────────
// SCREEN: Map Edit + Item Picker (Item / Display / Visible Range drum)
// Variant of ScreenMapEdit with the 3-column drum at bottom.
// ─────────────────────────────────────────────────────────────
function ScreenMapEditPicker({ onCancel, onSave, onDone }) {
  const [item, setItem] = React.useState('hint');
  const [disp, setDisp] = React.useState('Normal');
  const [range, setRange] = React.useState(30);

  return (
    <div className="ps-screen">
      <PSStatusBar/>

      {/* Top bar */}
      <div style={{ display: 'flex', alignItems: 'center', gap: 8, padding: '6px 12px 10px' }}>
        <button onClick={onCancel} className="ps-btn ps-btn--ghost ps-btn--sm" style={{ width: 64 }}>CANCEL</button>
        <div className="ps-grow" style={{ textAlign: 'center' }}>
          <div className="ps-cap" style={{ fontSize: 9, color: 'var(--duo-hare)' }}>EDIT ITEM</div>
          <div style={{ fontFamily: 'var(--font-display)', fontWeight: 900, fontSize: 15, color: 'var(--duo-eel-2)' }}>
            아이템 설정
          </div>
        </div>
        <button onClick={onSave} className="ps-btn ps-btn--primary ps-btn--sm" style={{ width: 64 }}>SAVE</button>
      </div>

      {/* Map (smaller — picker takes bottom half) */}
      <div style={{ position: 'relative', height: 240, overflow: 'hidden', background: '#c9d9ad' }}>
        <svg width="100%" height="100%" viewBox="0 0 320 240" preserveAspectRatio="none" style={{ position: 'absolute', inset: 0 }}>
          <rect width="320" height="240" fill="#c9d9ad"/>
          <path d="M-20 80 Q160 60 340 100" stroke="#fff" strokeWidth="14" fill="none"/>
          <path d="M0 200 Q120 170 340 190" stroke="#fff" strokeWidth="14" fill="none"/>
          <rect x="40" y="90" width="80" height="40" rx="3" fill="#f0e6cf" stroke="#cabd96"/>
          <rect x="180" y="50" width="80" height="60" rx="3" fill="#f0e6cf" stroke="#cabd96"/>
        </svg>
        {/* Effective radius preview */}
        <div style={{
          position: 'absolute',
          left: '50%', top: '50%',
          width: range * 2.4, height: range * 2.4,
          marginLeft: -range * 1.2, marginTop: -range * 1.2,
          borderRadius: '50%',
          background: `${GAME_ITEMS[item].tint}33`,
          border: `2px dashed ${GAME_ITEMS[item].deep}`,
        }}/>
        <div style={{ position: 'absolute', left: '50%', top: '50%', marginLeft: -22, marginTop: -28 }}>
          <ItemPin kind={item} size={44} glow active={GAME_ITEMS[item].essential}/>
        </div>
        {/* Helper toast */}
        <div style={{
          position: 'absolute', left: 8, right: 8, bottom: 8,
          background: 'rgba(20,15,12,0.85)',
          color: '#fff', padding: '6px 10px',
          borderRadius: 10, fontSize: 10,
        }}>
          ⓘ Item Touch: Setting · Item Drag: Move
        </div>
      </div>

      {/* Toolbar that mimics the legacy "Item · Display · Visible Range · Cancel · Done" */}
      <div style={{
        background: 'linear-gradient(180deg, #4a4a4a 0%, #2d2d2d 100%)',
        padding: '8px 10px',
        display: 'flex', alignItems: 'center', gap: 8,
        borderBottom: '2px solid #1a1a1a',
      }}>
        <div className="ps-cap" style={{ fontSize: 9, color: '#fff', letterSpacing: '0.04em' }}>
          ITEM
        </div>
        <div className="ps-cap" style={{ fontSize: 9, color: 'rgba(255,255,255,0.6)' }}>
          DISPLAY
        </div>
        <div className="ps-cap" style={{ fontSize: 9, color: 'rgba(255,255,255,0.6)' }}>
          VISIBLE RANGE
        </div>
        <div style={{ flex: 1 }}/>
        <button onClick={onCancel} className="ps-btn ps-btn--ghost-dark ps-btn--xs">CANCEL</button>
        <button onClick={onDone} className="ps-btn ps-btn--blue ps-btn--xs">DONE</button>
      </div>

      {/* 3-column drum */}
      <div style={{
        flex: 1,
        background: 'linear-gradient(180deg, #d8d8d8 0%, #f5f5f5 50%, #d8d8d8 100%)',
        display: 'flex',
        position: 'relative',
        overflow: 'hidden',
      }}>
        <DrumColumn options={[
          'start', 'end', 'hint', 'quiz', 'solution',
          'gambling', 'runStart', 'runEnd', 'mine', 'defence',
          'mineRadar', 'mapRadar', 'stealthRadar',
        ]}
          value={item} onChange={setItem}
          render={(k) => GAME_ITEMS[k]?.name || k}/>

        <DrumColumn options={['Normal', 'Hidden', 'Stealth', 'hide map', 'lock']}
          value={disp} onChange={setDisp}
          render={(v) => v}/>

        <DrumColumn options={[10, 20, 30, 40, 50, 60, 70, 80, 90, 100]}
          value={range} onChange={setRange}
          render={(v) => v}/>

        {/* Center selection band */}
        <div style={{
          position: 'absolute', left: 8, right: 8, top: '50%',
          height: 32, marginTop: -16,
          background: 'rgba(28,176,246,0.08)',
          border: '1px solid rgba(28,176,246,0.4)',
          borderTop: '1px solid rgba(28,176,246,0.4)',
          borderBottom: '1px solid rgba(28,176,246,0.4)',
          pointerEvents: 'none',
        }}/>
      </div>
    </div>
  );
}

function DrumColumn({ options, value, onChange, render }) {
  const idx = options.indexOf(value);
  const ROW_H = 32;
  return (
    <div style={{
      flex: 1,
      position: 'relative',
      borderRight: '1px solid rgba(0,0,0,0.1)',
      overflow: 'hidden',
    }}>
      {/* gradient fades */}
      <div style={{
        position: 'absolute', top: 0, left: 0, right: 0, height: 30, zIndex: 2,
        background: 'linear-gradient(180deg, #d8d8d8 0%, transparent 100%)',
        pointerEvents: 'none',
      }}/>
      <div style={{
        position: 'absolute', bottom: 0, left: 0, right: 0, height: 30, zIndex: 2,
        background: 'linear-gradient(0deg, #d8d8d8 0%, transparent 100%)',
        pointerEvents: 'none',
      }}/>
      <div style={{
        position: 'relative',
        transform: `translateY(calc(50% - ${ROW_H/2}px - ${idx * ROW_H}px))`,
        transition: 'transform 0.2s',
      }}>
        {options.map((opt, i) => (
          <div key={String(opt)} onClick={() => onChange(opt)} style={{
            height: ROW_H,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            fontFamily: 'var(--font-display)',
            fontWeight: i === idx ? 900 : 700,
            fontSize: i === idx ? 15 : 12,
            color: i === idx ? 'var(--duo-eel-2)' : 'var(--duo-hare)',
            cursor: 'pointer',
            opacity: Math.max(0.3, 1 - Math.abs(i - idx) * 0.25),
            transition: 'all 0.15s',
          }}>
            {render(opt)}
          </div>
        ))}
      </div>
    </div>
  );
}


Object.assign(window, {
  ScreenDesignList, ScreenDesignAction, ScreenMissionInfo,
  ScreenMissionSettings, ScreenItemDetail, ScreenMapEditPicker,
});
