// PlaySpot — iPhone device shell. Custom (not iOS 26) so we can mimic the
// older iPhone 4S-ish look of the source screenshots, but cleaner.
//
// Width: 320, Height: 568 — original screenshots are iPhone 4S/5 ratio.

function PSPhone({ children, width = 320, height = 568, dark = false }) {
  const bezel = 22;
  return (
    <div style={{
      width: width + bezel * 2,
      height: height + 110, // 54 top + 56 bottom
      borderRadius: 56,
      background: dark ? '#0a0a0a' : '#1a1d22',
      padding: `54px ${bezel}px 56px`,
      position: 'relative',
      boxShadow: '0 30px 50px rgba(0,0,0,0.35), inset 0 0 0 2px rgba(255,255,255,0.06), inset 0 0 0 3px rgba(0,0,0,0.45)',
      boxSizing: 'border-box',
      fontFamily: 'var(--font-body)',
    }}>
      {/* Speaker */}
      <div style={{
        position: 'absolute', top: 22, left: '50%', transform: 'translateX(-50%)',
        width: 56, height: 6, borderRadius: 3,
        background: '#0a0c0e',
      }} />
      {/* Camera */}
      <div style={{
        position: 'absolute', top: 18, left: '50%', transform: 'translateX(-90px)',
        width: 8, height: 8, borderRadius: 4,
        background: '#0a0c0e',
        boxShadow: 'inset 0 0 0 1px rgba(70,90,110,0.6)',
      }} />
      {/* Screen */}
      <div style={{
        width: '100%', height: '100%',
        borderRadius: 6, overflow: 'hidden',
        background: '#fff',
        position: 'relative',
      }}>
        {children}
      </div>
      {/* Home button */}
      <div style={{
        position: 'absolute', bottom: 12, left: '50%', transform: 'translateX(-50%)',
        width: 40, height: 40, borderRadius: '50%',
        background: '#0a0c0e',
        boxShadow: 'inset 0 0 0 2px rgba(80,90,100,0.5)',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
      }}>
        <div style={{ width: 18, height: 18, borderRadius: 4, border: '1.5px solid rgba(140,150,160,0.6)' }} />
      </div>
    </div>
  );
}

// Fake status bar that sits at top of screen content
function PSStatusBar({ time = '4:11', onDark = false }) {
  const color = onDark ? '#fff' : '#1c1c1c';
  return (
    <div className={`ps-status ${onDark ? 'on-dark' : ''}`}>
      <div className="ps-row" style={{ gap: 6 }}>
        <PSIcons.Signal color={color}/>
        <span style={{ fontSize: 11, fontWeight: 600, color }}>olleh</span>
        <PSIcons.Wifi color={color}/>
      </div>
      <div className="ps-time" style={{ color }}>오후 {time}</div>
      <div className="ps-row" style={{ gap: 4 }}>
        <svg width="12" height="12" viewBox="0 0 24 24" fill={color}><path d="M3 21l18-9L3 3v7l13 2-13 2z"/></svg>
        <PSIcons.Battery color={color}/>
      </div>
    </div>
  );
}

Object.assign(window, { PSPhone, PSStatusBar });
