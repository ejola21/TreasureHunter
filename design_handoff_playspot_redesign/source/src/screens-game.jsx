// PlaySpot — in-game screens: Map Play, AR (Searching/Found), Hint Popup

// ─────────────────────────────────────────────────────────────
// SCREEN: Map Play — in-mission map view
// ─────────────────────────────────────────────────────────────
function ScreenMapPlay({ accent = 'green', onCamera, onExit }) {
  // Game stats — "지뢰 / 남은필수 / Hide Map / Stealth"
  return (
    <div className="ps-screen">
      <PSStatusBar />
      {/* Top game HUD */}
      <div style={{
        padding: '6px 12px 10px',
        background: 'linear-gradient(180deg, var(--theme-primary) 0%, var(--theme-primary-shadow) 100%)',
        display: 'flex', alignItems: 'center', gap: 8, borderBottom: "1.5px solid rgb(49, 121, 132)", borderTopColor: "rgb(49, 121, 132)", borderRightColor: "rgb(49, 121, 132)", borderLeftColor: "rgb(49, 121, 132)", opacity: "1"

      }}>
        <button onClick={onExit} style={{ width: 64, height: 36, borderRadius: 10, background: '#FF4B4B', border: '1.5px solid #d33', color: '#fff', fontFamily: 'var(--font-display)', fontWeight: 900, fontSize: 13, letterSpacing: '0.06em', cursor: 'pointer', padding: 0 }}>EXIT</button>
        <div style={{ flex: 1, display: 'flex', justifyContent: 'center', gap: 2, alignItems: 'center' }}>
          {'00:00:05'.split('').map((c, i) =>
          c === ':' ?
          <div key={i} style={{
            fontFamily: 'var(--font-display)', fontWeight: 900,
            fontSize: 20, color: '#fff', padding: '0 2px'
          }}>:</div> :

          <div key={i} className="ps-digit dark" style={{ width: 20, height: 30, fontSize: 18 }}>{c}</div>

          )}
        </div>
        <FlatHudButton title="현재 위치로" variant="white">
          <LocateIcon size={20} color="#1c8a9f" />
        </FlatHudButton>
        <FlatHudButton title="진행 사항" variant="blue">
          <InfoIcon size={20} color="#fff" />
        </FlatHudButton>
      </div>

      {/* Map area — fills remaining space, HUD overlays on top */}
      <div style={{ flex: 1, position: 'relative', overflow: 'hidden' }}>
        <div className="ps-map" style={{ height: "408px" }} />
        {/* roads */}
        <div className="ps-road" style={{ left: -20, top: 80, width: 200, height: 14, transform: 'rotate(-12deg)' }} />
        <div className="ps-road" style={{ right: -30, top: 40, width: 180, height: 12, transform: 'rotate(18deg)' }} />
        <div className="ps-road" style={{ left: 60, top: 200, width: 14, height: 240 }} />
        {/* buildings */}
        <div className="ps-building" style={{ left: 12, top: 110, width: 50, height: 40 }} />
        <div className="ps-building" style={{ left: 200, top: 70, width: 60, height: 100 }} />
        <div className="ps-building" style={{ left: 90, top: 230, width: 80, height: 50 }} />
        <div className="ps-building" style={{ left: 30, top: 300, width: 70, height: 60 }} />
        <div className="ps-building" style={{ right: 12, top: 250, width: 70, height: 80 }} />
        {/* place names */}
        <div style={{ position: 'absolute', left: 30, top: 230, fontSize: 8, color: '#7a6f55', fontWeight: 700 }}>SK Guest House</div>
        <div style={{ position: 'absolute', right: 30, top: 180, fontSize: 8, color: '#7a6f55', fontWeight: 700 }}>이노에이스</div>
        <div style={{ position: 'absolute', left: 40, top: 380, fontSize: 8, color: '#7a6f55', fontWeight: 700 }}>국제백신연구소</div>

        {/* Mission area highlight */}
        <div style={{
          position: 'absolute', left: 90, top: 240, width: 180, height: 180,
          borderRadius: '50%', background: 'rgba(28,176,246,0.18)',
          border: '2px dashed rgba(28,176,246,0.5)'
        }} />

        {/* Pins */}
        <div style={{ position: 'absolute', left: 175, top: 70 }}><ItemPin kind="quiz" size={36} active /></div>
        <div style={{ position: 'absolute', left: 88, top: 150 }}><ItemPin kind="mapRadar" size={36} /></div>
        <div style={{ position: 'absolute', left: 138, top: 130 }}>
          <svg width="34" height="38" viewBox="0 0 40 50" fill="none">
            <path d="M8 6 L8 30 L30 18 Z" fill="#1d1d1d" />
            <line x1="8" y1="6" x2="8" y2="46" stroke="#3c3c3c" strokeWidth="2.5" />
            <path d="M8 8h22M8 14h22M8 20h22M8 26h22" stroke="#fff" strokeWidth="1" opacity="0.4" />
          </svg>
        </div>
        <div style={{ position: 'absolute', left: 95, top: 220 }}><ItemPin kind="store" size={32} active /></div>
        <div style={{ position: 'absolute', left: 95, top: 280 }}><ItemPin kind="end" size={32} active /></div>

        {/* Player position */}
        <div style={{ position: 'absolute', left: 160, top: 320, width: 24, height: 24 }}>
          <div className="ps-pulse-ring" style={{ inset: -8, borderColor: 'var(--duo-macaw)' }} />
          <div style={{
            width: 24, height: 24, borderRadius: '50%',
            background: 'var(--duo-macaw)', border: '3px solid #fff',
            boxShadow: '0 2px 0 0 rgba(0,0,0,0.2)'
          }} />
        </div>
      </div>

      {/* Bottom stat bar — absolute overlay on map, segmented colors */}
      <div style={{
        position: 'absolute', left: 0, right: 0, bottom: 0,
        zIndex: 5
      }}>
        {/* Camera button — floats above */}
        <button onClick={onCamera} style={{
          position: 'absolute',
          left: '50%', top: -22,
          transform: 'translateX(-50%)',
          width: 62, height: 62, borderRadius: '50%',
          background: 'radial-gradient(circle at 35% 30%, #4dd0e4 0%, #1c8a9f 70%, #0e6675 100%)',
          color: '#fff',
          border: '1.5px solid #fff',
          boxShadow: '0 4px 0 0 #0e3a42, 0 6px 12px rgba(0,0,0,0.3)',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          cursor: 'pointer',
          zIndex: 2,
          padding: 0
        }}>
          <CameraIcon size={32} />
        </button>

        <div style={{
          borderRadius: 0,
          borderTop: '1.5px solid rgba(255,255,255,0.25)',
          boxShadow: '0 -2px 8px rgba(0,0,0,0.25)',
          padding: 0,
          display: 'grid',
          gridTemplateColumns: '1fr 1fr 70px 1fr 1fr',
          alignItems: 'stretch',
          overflow: 'hidden'
        }}>
          <StatSeg label="남은지형" value="001" tint="#fff" segBg="linear-gradient(180deg, rgba(42,135,148,0.92) 0%, rgba(26,94,105,0.92) 100%)" radius="left" />
          <StatSeg label="남은필수" value="004" tint="#FFC800" segBg="linear-gradient(180deg, rgba(26,94,105,0.95) 0%, rgba(14,58,66,0.95) 100%)" />
          <div style={{ background: 'rgba(14,58,66,0.85)' }} />
          <StatSeg label="Hidden" value="001" tint="#fff" segBg="linear-gradient(180deg, rgba(26,94,105,0.95) 0%, rgba(14,58,66,0.95) 100%)" />
          <StatSeg label="Stealth" value="000" tint="#fff" segBg="linear-gradient(180deg, rgba(42,135,148,0.92) 0%, rgba(26,94,105,0.92) 100%)" radius="right" />
        </div>
      </div>
    </div>);

}


// Flat (non-3D) HUD button used in the top game bar
function FlatHudButton({ children, onClick, variant = 'white' }) {
  const isBlue = variant === 'blue';
  return (
    <button onClick={onClick} style={{
      width: 36, height: 36, borderRadius: 10,
      background: isBlue ? '#1CB0F6' : '#fff',
      border: `1.5px solid ${isBlue ? '#1899d6' : '#d8d8d8'}`,
      boxShadow: 'none',
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      cursor: 'pointer',
      padding: 0
    }}>
      {children}
    </button>);

}

// "Locate me" — concentric crosshair with center dot + small arrow indicator
function LocateIcon({ size = 20, color = '#1c8a9f' }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none">
      <circle cx="12" cy="12" r="7" stroke={color} strokeWidth="2" />
      <circle cx="12" cy="12" r="2.5" fill={color} />
      <line x1="12" y1="2" x2="12" y2="5" stroke={color} strokeWidth="2" strokeLinecap="round" />
      <line x1="12" y1="19" x2="12" y2="22" stroke={color} strokeWidth="2" strokeLinecap="round" />
      <line x1="2" y1="12" x2="5" y2="12" stroke={color} strokeWidth="2" strokeLinecap="round" />
      <line x1="19" y1="12" x2="22" y2="12" stroke={color} strokeWidth="2" strokeLinecap="round" />
    </svg>);

}

// "Progress" — vertical bar chart (3 ascending bars)
function ChecklistIcon({ size = 20, color = '#fff' }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none">
      {/* 3 rows: a checked box, an empty box, an empty box */}
      <rect x="3" y="4" width="6" height="6" rx="1.2" stroke={color} strokeWidth="2" />
      <path d="M4.5 7 L6 8.5 L8 5.5" stroke={color} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" fill="none" />
      <line x1="11" y1="7" x2="21" y2="7" stroke={color} strokeWidth="2" strokeLinecap="round" />

      <rect x="3" y="11" width="6" height="6" rx="1.2" stroke={color} strokeWidth="2" />
      <path d="M4.5 14 L6 15.5 L8 12.5" stroke={color} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" fill="none" />
      <line x1="11" y1="14" x2="21" y2="14" stroke={color} strokeWidth="2" strokeLinecap="round" />

      <rect x="3" y="18" width="6" height="6" rx="1.2" stroke={color} strokeWidth="2" />
      <line x1="11" y1="21" x2="21" y2="21" stroke={color} strokeWidth="2" strokeLinecap="round" />
    </svg>);

}

// "Info" — circle with "i"
function InfoIcon({ size = 20, color = '#fff' }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none">
      <circle cx="12" cy="12" r="9" stroke={color} strokeWidth="2" />
      <circle cx="12" cy="8" r="1.2" fill={color} />
      <line x1="12" y1="11" x2="12" y2="17" stroke={color} strokeWidth="2" strokeLinecap="round" />
    </svg>);

}

function ProgressIcon({ size = 20, color = '#fff' }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill={color}>
      <rect x="4" y="13" width="4" height="7" rx="1" />
      <rect x="10" y="9" width="4" height="11" rx="1" />
      <rect x="16" y="5" width="4" height="15" rx="1" />
    </svg>);

}

function Stat({ label, value, tint = '#fff', big = false }) {
  return (
    <div style={{ textAlign: 'center', color: '#fff' }}>
      <div style={{
        fontFamily: 'var(--font-display)', fontWeight: 800,
        fontSize: 10, letterSpacing: '0.06em', textTransform: 'uppercase',
        color: 'rgba(255,255,255,0.6)', marginBottom: 2
      }}>{label}</div>
      <div style={{
        fontFamily: 'var(--font-display)', fontWeight: 900,
        fontSize: big ? 18 : 16, color: tint, letterSpacing: '0.02em'
      }}>{value}</div>
    </div>);

}

// Segmented stat — used inside the HUD bar, each with its own bg tint.
function StatSeg({ label, value, tint = '#fff', segBg, radius }) {
  return (
    <div style={{
      position: 'relative',
      textAlign: 'center',
      padding: '8px 4px 8px',
      background: segBg || 'transparent',
      borderTopLeftRadius: radius === 'left' ? 11 : 0,
      borderBottomLeftRadius: radius === 'left' ? 11 : 0,
      borderTopRightRadius: radius === 'right' ? 11 : 0,
      borderBottomRightRadius: radius === 'right' ? 11 : 0,
      boxShadow: 'inset 0 1px 0 0 rgba(255,255,255,0.12), inset 0 -1px 0 0 rgba(0,0,0,0.2)'
    }}>
      <div style={{
        fontFamily: 'var(--font-display)', fontWeight: 800,
        fontSize: 10, letterSpacing: '0.04em',
        color: 'rgba(255,255,255,0.85)',
        textShadow: '0 1px 0 rgba(0,0,0,0.35)',
        marginBottom: 1
      }}>{label}</div>
      <div style={{
        fontFamily: 'var(--font-display)', fontWeight: 900,
        fontSize: 16, color: tint, letterSpacing: '0.04em',
        textShadow: '0 1px 0 rgba(0,0,0,0.4)'
      }}>{value}</div>
    </div>);

}

// More detailed camera icon — body + lens highlight + flash dot
function CameraIcon({ size = 32 }) {
  return (
    <svg width={size} height={size} viewBox="0 0 32 32" fill="none">
      {/* body */}
      <rect x="3" y="9" width="26" height="17" rx="3" fill="#fff" stroke="#fff" strokeWidth="0.5" />
      {/* viewfinder bump */}
      <path d="M11 9 L13 6 L19 6 L21 9 Z" fill="#fff" />
      {/* lens outer ring */}
      <circle cx="16" cy="17.5" r="6" fill="#1c8a9f" stroke="#0e6675" strokeWidth="1.2" />
      {/* lens inner */}
      <circle cx="16" cy="17.5" r="4" fill="#0e3a42" />
      {/* lens highlight */}
      <circle cx="14.5" cy="16" r="1.4" fill="#fff" opacity="0.85" />
      {/* flash dot */}
      <circle cx="25" cy="12" r="1.2" fill="#FFC800" />
    </svg>);

}

// ─────────────────────────────────────────────────────────────
// SCREEN: AR Searching — camera view, distance to target
// ─────────────────────────────────────────────────────────────
function ScreenARSearch({ onMap }) {
  return (
    <div className="ps-screen dark" style={{ background: '#000' }}>
      <PSStatusBar onDark />
      <ARTopBar onMap={onMap} time="00:09:00" />
      {/* Fake camera view: lush green outdoors */}
      <div style={{ flex: 1, position: 'relative', overflow: 'hidden' }}>
        <div className="ps-ar-bg" />
        {/* Sky band */}
        <div style={{
          position: 'absolute', top: 0, left: 0, right: 0, height: 90,
          background: 'linear-gradient(180deg, #84b9d3 0%, #b4d5c9 100%)'
        }} />
        {/* Tree silhouettes */}
        <svg width="100%" height="100%" viewBox="0 0 320 480" style={{ position: 'absolute', inset: 0 }} preserveAspectRatio="none">
          <ellipse cx="60" cy="80" rx="60" ry="60" fill="#3d6b2f" />
          <ellipse cx="270" cy="60" rx="80" ry="70" fill="#365e29" />
          <ellipse cx="160" cy="40" rx="70" ry="50" fill="#43782f" />
          <rect x="155" y="120" width="14" height="200" fill="#5c3a1a" />
          <ellipse cx="162" cy="200" rx="50" ry="40" fill="#73954a" />
          {/* Ground */}
          <path d="M0 320 L320 320 L320 480 L0 480 Z" fill="#5a4a2a" />
          <path d="M0 320 Q100 310 220 330 Q280 340 320 320 L320 360 L0 360 Z" fill="#cfb87a" />
        </svg>



        {/* Floating "Start" pin AR overlay */}
        <div className="ps-ar-pin" style={{ position: 'absolute', left: 80, top: 230 }}>
          {/* Outward shockwave pulse rings */}
          <div className="ps-ar-pin-pulse"/>
          <div className="ps-ar-pin-pulse" style={{ animationDelay: '0.8s' }}/>
          {/* Ground halo — pulses */}
          <div className="ps-ar-pin-halo"/>
          {/* Rotating conic glow ring */}
          <div className="ps-ar-pin-ring"/>
          {/* Bobbing wrapper */}
          <div className="ps-ar-pin-bob">
            <div className="ps-ar-pin-sway">
              <div className="ps-ar-pin-pop">
                <ItemPin kind="start" size={56} active glow />
              </div>
            </div>
          </div>
          {/* Sparkles flying up */}
          <div className="ps-ar-pin-spark" style={{ left: -2, top: 16, animationDelay: '0s', background: '#FFC800' }}/>
          <div className="ps-ar-pin-spark" style={{ left: 54, top: 20, animationDelay: '0.7s', background: '#FF9600' }}/>
          <div className="ps-ar-pin-spark" style={{ left: 26, top: -2, animationDelay: '1.4s', background: '#FFFFFF' }}/>
        </div>
      </div>

      {/* Bottom AR HUD */}
      <ARBottomHud distLabel="Start" dist="2m" radius="100m" />
    </div>);

}

// ─────────────────────────────────────────────────────────────
// SCREEN: AR Found — the "PlaySpot" mini-game when you're close
// Two variants: shake (motion) and touch (tap). Each interaction fills
// the PLAY SPOT wordmark progress. Hits the hint popup at 100%.
// ─────────────────────────────────────────────────────────────
function ScreenARFound({ variant = 'touch', onMap, onTap }) {
  const isShake = variant === 'party' || variant === 'shake';
  const [progress, setProgress] = React.useState(7);
  const target = 100;
  const [burst, setBurst] = React.useState(0); // bumps a key to retrigger anim
  const [glow, setGlow] = React.useState(false);

  // Auto-shake idle animation cycles the sparkle frame
  const [autoFrame, setAutoFrame] = React.useState(0);
  React.useEffect(() => {
    const t = setInterval(() => setAutoFrame((f) => 1 - f), 700);
    return () => clearInterval(t);
  }, []);

  const tick = () => {
    setBurst((b) => b + 1);
    setGlow(true);
    setTimeout(() => setGlow(false), 350);
    setProgress((p) => {
      const next = Math.min(target, p + 4 + Math.floor(Math.random() * 5));
      if (next >= target) setTimeout(() => onTap?.(), 400);
      return next;
    });
  };

  // While glow is on, show the "_1" (sparkle/burst) frame; otherwise alternate
  const showSparkle = glow || autoFrame === 1;
  const asset = isShake ?
  showSparkle ? 'assets/minigame/shake_1.png' : 'assets/minigame/shake_0.png' :
  showSparkle ? 'assets/minigame/touch_1.png' : 'assets/minigame/touch_0.png';

  return (
    <div className="ps-screen dark" style={{ background: '#0a0a0a' }}>
      <PSStatusBar onDark />
      <ARTopBarProgress onMap={onMap} progress={progress} target={target} />
      <div style={{ flex: 1, position: 'relative', overflow: 'hidden' }}>
        {/* Background outlined PLAY SPOT wordmark */}
        <OutlinedWordmark progress={progress / target} />

        {/* Burst sparkle layer (CSS particles) — retriggers on every tick */}
        <SparkleBurst key={burst} active={glow} />

        {/* Glow halo behind phone when active */}
        {glow &&
        <div style={{
          position: 'absolute',
          left: '50%', top: '48%',
          transform: 'translate(-50%, -50%)',
          width: 300, height: 300,
          borderRadius: '50%',
          background: 'radial-gradient(circle, rgba(255,200,0,0.35) 0%, transparent 60%)',
          pointerEvents: 'none',
          animation: 'ps-burst-glow 0.35s ease-out'
        }} />
        }

        {/* Foreground phone hand */}
        <div onClick={tick} style={{
          position: 'absolute',
          left: '50%', top: '48%',
          transform: 'translate(-50%, -50%)',
          width: 240, height: 240,
          cursor: 'pointer',
          animation: isShake ?
          'ps-shake 0.45s ease-in-out infinite' :
          'ps-bob 1.4s ease-in-out infinite',
          userSelect: 'none'
        }}>
          <img src={asset} alt="" draggable={false}
          style={{
            width: '100%', height: '100%', objectFit: 'contain',
            filter: glow ?
            'drop-shadow(0 6px 12px rgba(0,0,0,0.5)) drop-shadow(0 0 12px rgba(255,200,0,0.8))' :
            'drop-shadow(0 6px 12px rgba(0,0,0,0.5))',
            transition: 'filter 0.15s'
          }} />
        </div>

        {/* Bottom strip — instruction + progress */}
        <div style={{
          position: 'absolute', left: 0, right: 0, bottom: 0,
          padding: '10px 14px 12px',
          display: 'flex', alignItems: 'center', justifyContent: 'space-between',
          background: 'linear-gradient(180deg, transparent 0%, rgba(0,0,0,0.7) 60%)'
        }}>
          <div style={{
            fontFamily: 'var(--font-display)', fontWeight: 900,
            fontSize: 16, color: '#fff',
            textShadow: '0 2px 0 rgba(0,0,0,0.5)'
          }}>
            {isShake ? '흔드세요!' : '터치하세요!'}
          </div>
          <div style={{
            fontFamily: 'var(--font-display)', fontWeight: 900,
            fontSize: 16, color: '#fff'
          }}>
            <span style={{ color: '#FFC800' }}>{progress}</span>
            <span style={{ opacity: 0.6 }}> / {target}</span>
          </div>
        </div>
      </div>

      <ARBottomHud distLabel="Hint" dist="0m" radius="100m" />

      <style>{`
        @keyframes ps-shake {
          0%, 100% { transform: translate(-50%, -50%) rotate(-6deg); }
          25% { transform: translate(-52%, -50%) rotate(-8deg); }
          50% { transform: translate(-50%, -48%) rotate(6deg); }
          75% { transform: translate(-48%, -50%) rotate(8deg); }
        }
        @keyframes ps-bob {
          0%, 100% { transform: translate(-50%, -50%) scale(1); }
          50% { transform: translate(-50%, -52%) scale(1.04); }
        }
        @keyframes ps-burst-glow {
          0% { transform: translate(-50%, -50%) scale(0.5); opacity: 0; }
          50% { opacity: 1; }
          100% { transform: translate(-50%, -50%) scale(1.3); opacity: 0; }
        }
        @keyframes ps-sparkle-fly {
          0% { transform: translate(0, 0) scale(0); opacity: 0; }
          20% { transform: translate(var(--dx), var(--dy)) scale(1.2); opacity: 1; }
          100% { transform: translate(calc(var(--dx) * 1.8), calc(var(--dy) * 1.8)) scale(0.4) rotate(180deg); opacity: 0; }
        }
        @keyframes ps-sparkle-twinkle {
          0%, 100% { transform: scale(0.6) rotate(0deg); opacity: 0.4; }
          50% { transform: scale(1.2) rotate(180deg); opacity: 1; }
        }
      `}</style>
    </div>);

}

// Sparkle burst — 12 particles fly outward from center on each tap
function SparkleBurst({ active }) {
  const particles = React.useMemo(() =>
  Array.from({ length: 14 }).map((_, i) => {
    const angle = i / 14 * Math.PI * 2 + Math.random() * 0.3;
    const distance = 80 + Math.random() * 60;
    const dx = Math.cos(angle) * distance;
    const dy = Math.sin(angle) * distance;
    const colors = ['#FFC800', '#FF6B3D', '#1c8a9f', '#fff'];
    const color = colors[i % colors.length];
    const size = 12 + Math.random() * 8;
    return { dx, dy, color, size, delay: Math.random() * 0.08 };
  }),
  []);

  return (
    <div style={{
      position: 'absolute',
      left: '50%', top: '48%',
      width: 0, height: 0,
      pointerEvents: 'none',
      zIndex: 4
    }}>
      {particles.map((p, i) =>
      <div key={i} style={{
        position: 'absolute',
        left: 0, top: 0,
        '--dx': `${p.dx}px`,
        '--dy': `${p.dy}px`,
        animation: active ? `ps-sparkle-fly 0.7s ease-out ${p.delay}s both` : 'none',
        opacity: 0
      }}>
          <SparkleStar size={p.size} color={p.color} />
        </div>
      )}
      {/* Idle ambient twinkles */}
      {[
      { x: -110, y: -80, c: '#1c8a9f', s: 14, d: 0 },
      { x: 100, y: -60, c: '#FF6B3D', s: 18, d: 0.4 },
      { x: -80, y: 70, c: '#FFC800', s: 12, d: 0.8 },
      { x: 110, y: 90, c: '#1c8a9f', s: 16, d: 0.2 },
      { x: 0, y: -120, c: '#FF6B3D', s: 14, d: 1.0 }].
      map((s, i) =>
      <div key={`amb-${i}`} style={{
        position: 'absolute',
        left: s.x, top: s.y,
        animation: `ps-sparkle-twinkle 1.6s ease-in-out ${s.d}s infinite`
      }}>
          <SparkleStar size={s.s} color={s.c} />
        </div>
      )}
    </div>);

}

// 4-pointed sparkle star (Disney-style twinkle)
function SparkleStar({ size = 16, color = '#FFC800' }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24"
    style={{ display: 'block', marginLeft: -size / 2, marginTop: -size / 2 }}>
      <path d="M12 2 Q13 10 22 12 Q13 14 12 22 Q11 14 2 12 Q11 10 12 2 Z"
      fill={color} stroke="#fff" strokeWidth="0.8" strokeLinejoin="round" />
    </svg>);

}

// Outlined PLAY SPOT wordmark — uses the provided hand-drawn logo image.
// As progress increases the logo brightens/saturates and gains a glow halo.
function OutlinedWordmark({ progress = 0.36 }) {
  const fillPct = Math.max(0, Math.min(1, progress));
  // Map progress to a subtle visual change: dim → fully bright + warm glow
  const brightness = 0.55 + fillPct * 0.5; // 0.55 → 1.05
  const saturate = 0.4 + fillPct * 1.4; // 0.4  → 1.8
  const dropShadow = fillPct > 0.85 ?
  'drop-shadow(0 0 14px rgba(255,200,0,0.7))' :
  fillPct > 0.5 ?
  'drop-shadow(0 0 8px rgba(255,200,0,0.35))' :
  'none';
  return (
    <div style={{
      position: 'absolute', inset: 0,
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      pointerEvents: 'none'
    }}>
      <img src="assets/minigame/playspot_logo.png" alt="PLAY SPOT"
      draggable={false}
      style={{
        width: '78%', maxHeight: '70%',
        objectFit: 'contain',
        filter: `brightness(${brightness}) saturate(${saturate}) ${dropShadow}`,
        transition: 'filter 0.25s',
        userSelect: 'none'
      }} />
    </div>);

}

// Shared bottom HUD for AR screens — pill bar with integrated green radar
function ARBottomHud({ distLabel = 'Hint', dist = '36m', radius = '100m', itemKind = 'hint' }) {
  // Map distLabel → item kind so the right-side icon matches the active target
  const kindMap = { Start: 'start', End: 'end', Hint: 'hint' };
  const rightKind = kindMap[distLabel] || itemKind;
  return (
    <div style={{
      padding: '12px 10px 14px',
      background: 'transparent',
      position: 'relative'
    }}>
      {/* Radar — floats above center */}
      <div style={{
        position: 'absolute',
        left: '50%', top: -8,
        transform: 'translateX(-50%)',
        zIndex: 2
      }}>
        <ARRadar size={64} />
      </div>

      <div style={{
        background: 'linear-gradient(180deg, #1a5e69 0%, #0e3a42 100%)',
        borderRadius: 14,
        border: '1.5px solid rgba(255,255,255,0.25)',
        boxShadow: '0 3px 8px rgba(0,0,0,0.3), inset 0 1px 0 0 rgba(255,255,255,0.15)',
        display: 'flex', alignItems: 'center',
        height: 56, padding: '0 4px'
      }}>
        {/* Left side */}
        <div style={{
          flex: 1, display: 'flex', alignItems: 'center', gap: 8,
          padding: '0 12px'
        }}>
          <svg width="20" height="22" viewBox="0 0 20 22" fill="none">
            <line x1="3" y1="2" x2="3" y2="20" stroke="#fff" strokeWidth="2.5" strokeLinecap="round" />
            <path d="M3 3 L17 3 L13 8 L17 13 L3 13 Z" fill="#1CB0F6" stroke="#fff" strokeWidth="1.5" strokeLinejoin="round" />
          </svg>
          <div style={{
            fontFamily: 'var(--font-display)', fontWeight: 900,
            fontSize: 12, color: '#fff',
            textShadow: '0 1px 0 rgba(0,0,0,0.4)',
            lineHeight: 1.1,
            textAlign: 'left'
          }}>
            <div>{distLabel}</div>
            <div style={{ color: '#FFC800', fontSize: 14 }}>{dist}</div>
          </div>
        </div>

        {/* Center spacer for radar */}
        <div style={{ width: 56, flexShrink: 0 }} />

        {/* Right side */}
        <div style={{
          flex: 1, display: 'flex', alignItems: 'center', gap: 6,
          padding: '0 10px', justifyContent: 'flex-end'
        }}>
          <PinRadiusIcon size={22} />
          <div style={{
            fontFamily: 'var(--font-display)', fontWeight: 900,
            fontSize: 12, color: '#fff',
            textShadow: '0 1px 0 rgba(0,0,0,0.4)',
            lineHeight: 1.1,
            textAlign: 'left'
          }}>
            <div>유효 반경</div>
            <div style={{ color: '#1CB0F6', fontSize: 14 }}>{radius}</div>
          </div>
        </div>
      </div>
    </div>);

}

// Green map-marker-with-radius-disc icon — pin sitting on a flat radius ellipse
function PinRadiusIcon({ size = 22 }) {
  return (
    <svg width={size} height={size * 1.05} viewBox="0 0 22 24" fill="none">
      {/* Radius disc (flat ellipse) */}
      <ellipse cx="11" cy="20" rx="9" ry="2.5" fill="#7ed957" stroke="#3a8a2a" strokeWidth="1.2" />
      <ellipse cx="11" cy="19.5" rx="9" ry="2.5" fill="#a8e87f" />
      {/* Pin body */}
      <path d="M11 2 Q4 2 4 9 Q4 14 11 19 Q18 14 18 9 Q18 2 11 2 Z"
      fill="#7ed957" stroke="#2d6e1f" strokeWidth="1.5" strokeLinejoin="round" />
      {/* Inner circle */}
      <circle cx="11" cy="9" r="3.2" fill="#fff" stroke="#2d6e1f" strokeWidth="1.2" />
      {/* Highlight */}
      <ellipse cx="8" cy="5.5" rx="2" ry="1.2" fill="#fff" opacity="0.5" />
    </svg>);

}

// Green radar disc with sweep + crosshair + directional needle
function ARRadar({ size = 64, angle = 38 }) {
  return (
    <div style={{
      position: 'relative', width: size, height: size,
      borderRadius: '50%',
      background: 'radial-gradient(circle at 35% 30%, #6cd87f 0%, #2d8a3e 60%, #1a5223 100%)',
      border: '3px solid #fff',
      boxShadow: '0 4px 8px rgba(0,0,0,0.4), inset 0 0 0 2px #1a5223',
      overflow: 'hidden'
    }}>
      {/* Concentric rings */}
      <div style={{
        position: 'absolute', inset: 4, borderRadius: '50%',
        border: '1px solid rgba(255,255,255,0.35)'
      }} />
      <div style={{
        position: 'absolute', inset: 12, borderRadius: '50%',
        border: '1px solid rgba(255,255,255,0.3)'
      }} />
      {/* Crosshair */}
      <div style={{
        position: 'absolute', top: '50%', left: 4, right: 4, height: 1,
        background: 'rgba(255,255,255,0.4)'
      }} />
      <div style={{
        position: 'absolute', left: '50%', top: 4, bottom: 4, width: 1,
        background: 'rgba(255,255,255,0.4)'
      }} />
      {/* Sweep */}
      <div className="ps-spin" style={{
        position: 'absolute', inset: 0,
        background: 'conic-gradient(from 0deg, rgba(180,255,180,0.7) 0deg, transparent 70deg)',
        borderRadius: '50%'
      }} />
      {/* Directional needle — points toward the target item */}
      <div style={{
        position: 'absolute',
        top: '50%', left: '50%',
        width: 2, height: size * 0.42,
        marginLeft: -1, marginTop: -size * 0.42,
        transformOrigin: '50% 100%',
        transform: `rotate(${angle}deg)`,
        pointerEvents: 'none'
      }}>
        <svg width="14" height={size * 0.42} viewBox={`0 0 14 ${size * 0.42}`}
        style={{ position: 'absolute', left: -6, top: 0 }}>
          {/* shaft */}
          <line x1="7" y1={size * 0.42} x2="7" y2="6"
          stroke="#FFC800" strokeWidth="2" strokeLinecap="round" />
          {/* arrow head */}
          <path d={`M 7 0 L 12 8 L 7 6 L 2 8 Z`}
          fill="#FFC800" stroke="#A37800" strokeWidth="0.6" strokeLinejoin="round" />
        </svg>
      </div>
      {/* Center hub */}
      <div style={{
        position: 'absolute', top: '50%', left: '50%',
        width: 8, height: 8, marginLeft: -4, marginTop: -4,
        borderRadius: '50%', background: '#FFC800',
        border: '1.5px solid #A37800',
        boxShadow: '0 0 4px rgba(255,200,0,0.8)'
      }} />
      {/* Blip */}
      <div style={{
        position: 'absolute', top: '18%', left: '68%',
        width: 5, height: 5, borderRadius: '50%',
        background: '#fff',
        boxShadow: '0 0 5px #fff'
      }} />
    </div>);

}

// ─────────────────────────────────────────────────────────────
// SCREEN: Hint Acquired Popup — modal over AR background
// ─────────────────────────────────────────────────────────────
function ScreenHintPopup({ onConfirm, onMap }) {
  return (
    <div className="ps-screen dark" style={{ background: '#000' }}>
      <PSStatusBar onDark />
      <ARTopBar onMap={onMap} time="00:04:19" />
      <div style={{ flex: 1, position: 'relative', overflow: 'hidden' }}>
        {/* Backdrop: blurred AR */}
        <div style={{ position: 'absolute', inset: 0,
          background: 'radial-gradient(ellipse at 50% 60%, #6a3a30 0%, #2c1a13 60%, #1a0907 100%)',
          filter: 'blur(2px)'
        }} />
        <div style={{ position: 'absolute', inset: 0, background: 'rgba(0,0,0,0.35)' }} />


        {/* Modal card */}
        <div style={{
          position: 'absolute', left: 16, right: 16, top: 130,
          background: '#fff',
          border: '2px solid var(--duo-swan-2)',
          borderRadius: 18,
          boxShadow: '0 4px 0 0 var(--duo-swan-2), 0 20px 40px rgba(0,0,0,0.35)',
          padding: '18px 18px 22px'
        }}>
          {/* Hint pin floats off corner */}
          <div style={{ position: 'absolute', left: -16, top: -22 }}>
            <ItemPin kind="hint" size={58} active />
          </div>

          <div style={{
            display: 'flex', flexDirection: 'column', alignItems: 'center',
            paddingTop: 30
          }}>
            <div className="ps-cap" style={{ fontSize: 10, color: 'var(--duo-macaw)', letterSpacing: '0.1em', marginBottom: 4 }}>
              ITEM ACQUIRED · 아이템 획득
            </div>
            <div className="ps-display" style={{ fontSize: 30, color: 'var(--duo-eel-2)', marginBottom: 6 }}>
              Hint!
            </div>
            <div style={{
              fontSize: 13, color: 'var(--duo-wolf-2)',
              textAlign: 'center', lineHeight: 1.5,
              padding: '8px 0 18px'
            }}>
              힌트 아이템은 미션에 대한 힌트나<br />
              해당 지역에 대한 정보를 볼 수 있어요.
            </div>

            {/* Mini reward strip */}
            <div style={{
              display: 'flex', gap: 8, marginBottom: 18, width: '100%', justifyContent: 'center'
            }}>
              <Reward icon={<PSIcons.Bolt size={18} />} label="+15 XP" tint="#FFC800" />
              <Reward icon={<PSIcons.Gem size={18} />} label="+1" tint="#CE82FF" />
            </div>

            <button onClick={onConfirm} className="ps-btn ps-btn--primary" style={{ width: '100%' }}>
              확인 · OK
            </button>
          </div>
        </div>

        {/* Mission end strip */}
        <div style={{
          position: 'absolute', left: 0, right: 0, bottom: 0,
          background: 'var(--duo-eel-2)',
          padding: '14px 16px',
          display: 'flex', alignItems: 'center', justifyContent: 'space-between'
        }}>
          <Radar size={40} />
          <button className="ps-btn ps-btn--red ps-btn--sm" style={{ height: 40 }}>미션 종료!</button>
        </div>
      </div>
    </div>);

}

function Reward({ icon, label, tint }) {
  return (
    <div style={{
      display: 'flex', alignItems: 'center', gap: 6,
      background: '#f7f7f7', border: '2px solid var(--duo-swan)',
      borderRadius: 999, padding: '6px 12px',
      boxShadow: '0 2px 0 0 var(--duo-swan-2)'
    }}>
      {icon}
      <span style={{
        fontFamily: 'var(--font-display)', fontWeight: 800,
        fontSize: 13, color: tint
      }}>{label}</span>
    </div>);

}


// Shared dark top bar for AR screens — matches Map Play style

// Top bar variant for mini-game — shows progress/target counter instead of time
function ARTopBarProgress({ onMap, progress = 0, target = 100 }) {
  const timeStr = String(progress).padStart(6, '0').replace(/(.{2})(.{2})(.{2})/, '$1:$2:$3');
  return <ARTopBar onMap={onMap} time={timeStr} />;
}

function ARTopBar({ onMap, time = '00:09:00' }) {
  return (
    <div style={{
      background: 'linear-gradient(180deg, var(--theme-primary) 0%, var(--theme-primary-shadow) 100%)',
      borderBottom: '1.5px solid var(--theme-primary-text)',
      padding: '6px 12px 10px',
      display: 'flex', alignItems: 'center', gap: 8,
      position: 'relative', zIndex: 5
    }}>
      <button onClick={onMap} style={{
        width: 64, height: 36, borderRadius: 10,
        background: '#1c8a9f',
        border: '1.5px solid #0e6675',
        color: '#fff',
        fontFamily: 'var(--font-display)', fontWeight: 900,
        fontSize: 12, letterSpacing: '0.06em',
        cursor: 'pointer', padding: 0,
        display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 4
      }}>
        <PSIcons.Map size={14} color="#fff" /> MAP
      </button>
      <div style={{ flex: 1, display: 'flex', justifyContent: 'center', gap: 2, alignItems: 'center' }}>
        {time.split('').map((c, i) =>
        c === ':' ?
        <div key={i} style={{
          fontFamily: 'var(--font-display)', fontWeight: 900,
          fontSize: 20, color: '#fff', padding: '0 2px'
        }}>:</div> :

        <div key={i} className="ps-digit dark" style={{ width: 20, height: 30, fontSize: 18 }}>{c}</div>

        )}
      </div>
      <div style={{ width: 64 }} />
    </div>);

}

Object.assign(window, {
  ScreenMapPlay, ScreenARSearch, ScreenARFound, ScreenHintPopup
});