// PlaySpot — icon set: Lucide-style glyphs + custom game item pins + fox mascot

const PSIcons = (() => {
  const stroke = (paths, { size = 24, color = 'currentColor', sw = 2.5 } = {}) => (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={color}
         strokeWidth={sw} strokeLinecap="round" strokeLinejoin="round">{paths}</svg>
  );

  return {
    ArrowLeft: (p) => stroke(<><line x1="19" y1="12" x2="5" y2="12"/><polyline points="12 19 5 12 12 5"/></>, p),
    Close:     (p) => stroke(<><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></>, p),
    Plus:      (p) => stroke(<><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></>, p),
    Pencil:    (p) => stroke(<><path d="M12 20h9"/><path d="M16.5 3.5a2.1 2.1 0 1 1 3 3L7 19l-4 1 1-4 12.5-12.5z"/></>, p),
    Target:    (p) => stroke(<><circle cx="12" cy="12" r="9"/><circle cx="12" cy="12" r="4"/><circle cx="12" cy="12" r="1" fill="currentColor"/></>, p),
    Camera:    (p) => stroke(<><path d="M23 7l-7 5 7 5V7z"/><rect x="1" y="5" width="15" height="14" rx="2" ry="2"/></>, p),
    Compass:   (p) => stroke(<><circle cx="12" cy="12" r="9"/><polygon points="16.24 7.76 14.12 14.12 7.76 16.24 9.88 9.88 16.24 7.76"/></>, p),
    Camera2:   (p) => stroke(<><path d="M3 7h4l2-3h6l2 3h4v12H3z"/><circle cx="12" cy="13" r="4"/></>, p),
    Search:    (p) => stroke(<><circle cx="11" cy="11" r="7"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></>, p),
    Share:     (p) => stroke(<><path d="M4 12v8a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2v-8"/><polyline points="16 6 12 2 8 6"/><line x1="12" y1="2" x2="12" y2="15"/></>, p),
    Upload:    (p) => stroke(<><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><polyline points="17 8 12 3 7 8"/><line x1="12" y1="3" x2="12" y2="15"/></>, p),
    Map:       (p) => stroke(<><polygon points="1 6 8 3 16 6 23 3 23 18 16 21 8 18 1 21"/><line x1="8" y1="3" x2="8" y2="18"/><line x1="16" y1="6" x2="16" y2="21"/></>, p),
    Help:      (p) => stroke(<><circle cx="12" cy="12" r="9"/><path d="M9.1 9a3 3 0 0 1 5.8 1c0 2-3 2.5-3 4.5"/><circle cx="12" cy="17.5" r="1" fill="currentColor" stroke="none"/></>, p),
    Settings:  (p) => stroke(<><circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.6 1.6 0 0 0 .3 1.8l.1.1a2 2 0 1 1-2.8 2.8l-.1-.1a1.6 1.6 0 0 0-1.8-.3 1.6 1.6 0 0 0-1 1.5V21a2 2 0 1 1-4 0v-.1a1.6 1.6 0 0 0-1-1.5 1.6 1.6 0 0 0-1.8.3l-.1.1a2 2 0 1 1-2.8-2.8l.1-.1a1.6 1.6 0 0 0 .3-1.8 1.6 1.6 0 0 0-1.5-1H3a2 2 0 1 1 0-4h.1a1.6 1.6 0 0 0 1.5-1 1.6 1.6 0 0 0-.3-1.8l-.1-.1a2 2 0 1 1 2.8-2.8l.1.1a1.6 1.6 0 0 0 1.8.3 1.6 1.6 0 0 0 1-1.5V3a2 2 0 1 1 4 0v.1a1.6 1.6 0 0 0 1 1.5 1.6 1.6 0 0 0 1.8-.3l.1-.1a2 2 0 1 1 2.8 2.8l-.1.1a1.6 1.6 0 0 0-.3 1.8 1.6 1.6 0 0 0 1.5 1H21a2 2 0 1 1 0 4h-.1a1.6 1.6 0 0 0-1.5 1z"/></>, p),
    List:      (p) => stroke(<><line x1="8" y1="6" x2="20" y2="6"/><line x1="8" y1="12" x2="20" y2="12"/><line x1="8" y1="18" x2="20" y2="18"/><circle cx="4" cy="6" r="1" fill="currentColor" stroke="none"/><circle cx="4" cy="12" r="1" fill="currentColor" stroke="none"/><circle cx="4" cy="18" r="1" fill="currentColor" stroke="none"/></>, p),
    User:      (p) => stroke(<><circle cx="12" cy="8" r="4"/><path d="M4 21a8 8 0 0 1 16 0"/></>, p),
    Badge:     (p) => stroke(<><circle cx="12" cy="10" r="6"/><path d="M9 14l-2 7 5-3 5 3-2-7"/></>, p),
    Palette:   (p) => stroke(<><circle cx="12" cy="12" r="9"/><circle cx="7" cy="10" r="1.2" fill="currentColor" stroke="none"/><circle cx="11" cy="7" r="1.2" fill="currentColor" stroke="none"/><circle cx="16" cy="10" r="1.2" fill="currentColor" stroke="none"/><path d="M12 21a3 3 0 0 1-2-5 2 2 0 0 0 0-2c-1-1-1.5-2.5 0-4"/></>, p),
    Volume:    (p) => stroke(<><path d="M11 5L6 9H2v6h4l5 4z"/><path d="M15.5 8.5a5 5 0 0 1 0 7"/></>, p),
    Wifi:      ({ size = 14, color = "#fff" } = {}) => (
      <svg width={size} height={size} viewBox="0 0 24 24" fill={color}>
        <path d="M12 17.5a1.7 1.7 0 1 0 0 3.4 1.7 1.7 0 0 0 0-3.4zm-5-4.2a7 7 0 0 1 10 0l1.6-1.6a9.3 9.3 0 0 0-13.2 0L7 13.3zm-3-3a11.3 11.3 0 0 1 16 0l1.6-1.6a13.6 13.6 0 0 0-19.2 0L4 10.3z"/>
      </svg>
    ),
    Battery:   ({ size = 22, color = "#1c1c1c" } = {}) => (
      <svg width={size} height={size * 0.55} viewBox="0 0 22 12">
        <rect x="0.5" y="0.5" width="19" height="11" rx="2.5" stroke={color} fill="none"/>
        <rect x="2" y="2" width="16" height="8" rx="1.2" fill={color}/>
        <rect x="20" y="3.5" width="1.5" height="5" rx="0.6" fill={color}/>
      </svg>
    ),
    Signal:    ({ size = 18, color = "#1c1c1c" } = {}) => (
      <svg width={size} height={size * 0.7} viewBox="0 0 18 12">
        <rect x="0" y="9" width="3" height="3" rx="0.6" fill={color}/>
        <rect x="4" y="6.5" width="3" height="5.5" rx="0.6" fill={color}/>
        <rect x="8" y="3.5" width="3" height="8.5" rx="0.6" fill={color}/>
        <rect x="12" y="0.5" width="3" height="11.5" rx="0.6" fill={color}/>
      </svg>
    ),

    // Reward icons
    Flame: ({ size = 24 } = {}) => (
      <svg width={size} height={size} viewBox="0 0 24 28" fill="none">
        <path d="M9.5 1c1-1 2 0 2.5 1 1 2 2 3 4 4.5 2.5 2 6 5 6 10 0 5.5-4.7 10-10.5 10S1 22 1 16.5C1 14.5 2 13 3 11.5L4 10c.5-.7 1.2-.5 1.2.3v3.7c0 1.7 2 2 2 .3V4c0-1 1-2.5 2.3-3z" fill="#FE9504"/>
        <path d="M12 11c1-1 2 0 2.5 1 .5 1 1.5 2 2.5 3 1 1 2 2.5 2 4.5 0 3-2.5 5-5 5s-5-2-5-5c0-1.5.8-2.5 1.5-3.5l1-1.2c.5-.7 1-.5 1 .3v1.4c0 1 .8 1.2 1 0V13c0-.5.3-1.3 1-2z" fill="#FFC901"/>
      </svg>
    ),
    Bolt: ({ size = 24 } = {}) => (
      <svg width={size} height={size} viewBox="0 0 22 28" fill="none">
        <path d="M11 1L1 17h9l-2 10 14-18h-9l2-8z" fill="#FFC800" stroke="#D9A800" strokeWidth="1.5" strokeLinejoin="round"/>
      </svg>
    ),
    Heart: ({ size = 22, color = '#FF4B4B' } = {}) => (
      <svg width={size} height={size} viewBox="0 0 24 24" fill={color}>
        <path d="M12 21s-7-4.5-9.3-9.1C1.4 8.3 3 4 6.7 4c2 0 3.5 1.1 4.3 2.3.8-1.2 2.3-2.3 4.3-2.3 3.7 0 5.3 4.3 4 7.9C19 16.5 12 21 12 21z"/>
      </svg>
    ),
    Gem: ({ size = 24 } = {}) => (
      <svg width={size} height={size} viewBox="0 0 24 24" fill="none">
        <path d="M6 3h12l4 6-10 12L2 9z" fill="#CE82FF" stroke="#8C39C8" strokeWidth="1.4" strokeLinejoin="round"/>
        <path d="M6 3l-4 6h20l-4-6M9 3l3 6 3-6M2 9l10 12M22 9l-10 12" stroke="#8C39C8" strokeWidth="1.2"/>
      </svg>
    ),
    Star: ({ size = 24, color = '#FFC800' } = {}) => (
      <svg width={size} height={size} viewBox="0 0 24 24" fill={color} stroke="#D9A800" strokeWidth="1.4" strokeLinejoin="round">
        <path d="M12 2l3 7 7 .5-5.5 4.5L18 22l-6-4-6 4 1.5-8L2 9.5 9 9z"/>
      </svg>
    ),
    Trophy: ({ size = 24 } = {}) => (
      <svg width={size} height={size} viewBox="0 0 24 24" fill="none">
        <path d="M5 4h14v4a5 5 0 0 1-5 5h-4a5 5 0 0 1-5-5V4z" fill="#FFC800" stroke="#D9A800" strokeWidth="1.6"/>
        <path d="M9 14h6v3H9zM7 19h10v2H7z" fill="#D9A800"/>
      </svg>
    ),
  };
})();


// Fox mascot — friendly placeholder character (replacement for the original
// orange fox in the source). Multiple poses via `pose` prop.
function FoxMascot({ size = 80, pose = 'wave' }) {
  // Solid two-tone fox face, no expression nuance — placeholder per design system.
  return (
    <svg width={size} height={size * 1.0} viewBox="0 0 100 100" fill="none">
      {/* Body for "wave"/"sit" poses */}
      {pose === 'sit' && (
        <ellipse cx="50" cy="85" rx="34" ry="14" fill="#FF7733"/>
      )}
      {/* Ears */}
      <path d="M20 35 L24 12 L40 22 Z" fill="#FF9600"/>
      <path d="M80 35 L76 12 L60 22 Z" fill="#FF9600"/>
      <path d="M25 28 L27 18 L36 24 Z" fill="#FF4B4B"/>
      <path d="M75 28 L73 18 L64 24 Z" fill="#FF4B4B"/>
      {/* Head */}
      <ellipse cx="50" cy="50" rx="32" ry="30" fill="#FF9600"/>
      {/* Cheek mask */}
      <path d="M20 50 Q15 70 35 78 Q50 82 65 78 Q85 70 80 50 Q60 60 50 60 Q40 60 20 50 Z" fill="#FFE9D2"/>
      {/* Eye whites */}
      <ellipse cx="38" cy="48" rx="7" ry="8" fill="#fff"/>
      <ellipse cx="62" cy="48" rx="7" ry="8" fill="#fff"/>
      {/* Pupils */}
      <circle cx="39" cy="50" r="3.2" fill="#2D3339"/>
      <circle cx="63" cy="50" r="3.2" fill="#2D3339"/>
      <circle cx="40" cy="49" r="1" fill="#fff"/>
      <circle cx="64" cy="49" r="1" fill="#fff"/>
      {/* Brow */}
      {pose === 'think' && (<>
        <path d="M31 38 Q38 35 45 39" stroke="#A85800" strokeWidth="2.4" strokeLinecap="round" fill="none"/>
        <path d="M55 39 Q62 35 69 38" stroke="#A85800" strokeWidth="2.4" strokeLinecap="round" fill="none"/>
      </>)}
      {/* Nose */}
      <ellipse cx="50" cy="60" rx="4" ry="3" fill="#2D3339"/>
      {/* Mouth */}
      {pose === 'wave' && (
        <path d="M44 67 Q50 73 56 67" stroke="#2D3339" strokeWidth="2.4" strokeLinecap="round" fill="none"/>
      )}
      {pose === 'sit' && (
        <path d="M44 67 Q50 72 56 67" stroke="#2D3339" strokeWidth="2.4" strokeLinecap="round" fill="none"/>
      )}
      {pose === 'think' && (
        <path d="M44 70 Q50 67 56 70" stroke="#2D3339" strokeWidth="2.4" strokeLinecap="round" fill="none"/>
      )}
      {pose === 'cheer' && (<>
        <path d="M42 64 Q50 76 58 64 Q50 70 42 64 Z" fill="#2D3339"/>
        <path d="M44 68 Q50 73 56 68" stroke="#FF4B4B" strokeWidth="2" fill="#FF4B4B"/>
      </>)}
      {/* Hand wave */}
      {pose === 'wave' && (
        <g>
          <ellipse cx="86" cy="32" rx="9" ry="11" fill="#FF9600" stroke="#A85800" strokeWidth="1.5"/>
        </g>
      )}
    </svg>
  );
}


// Radar / compass widget
function Radar({ size = 56 }) {
  return (
    <div style={{
      position: 'relative', width: size, height: size,
      borderRadius: '50%',
      background: '#1d1612',
      border: `3px solid ${'#fff'}`,
      boxShadow: '0 4px 0 0 rgba(0,0,0,0.35), inset 0 0 0 2px #2a1f18',
      overflow: 'hidden',
    }}>
      <div style={{ position: 'absolute', inset: 4, borderRadius: '50%', border: '1px solid rgba(255,200,0,0.3)' }} />
      <div style={{ position: 'absolute', inset: 10, borderRadius: '50%', border: '1px solid rgba(255,200,0,0.25)' }} />
      <div className="ps-spin" style={{
        position: 'absolute', inset: 0,
        background: 'conic-gradient(from 0deg, rgba(255,200,0,0.6) 0deg, transparent 60deg)',
        borderRadius: '50%',
      }} />
      <div style={{
        position: 'absolute', top: '50%', left: '50%',
        width: 6, height: 6, marginLeft: -3, marginTop: -3,
        borderRadius: '50%', background: '#FFC800',
        boxShadow: '0 0 6px #FFC800',
      }} />
    </div>
  );
}

function PinGlyph() { return null; }
Object.assign(window, { PinGlyph });
