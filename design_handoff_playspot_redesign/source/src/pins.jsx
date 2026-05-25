// PlaySpot — game item definitions + pin component using real PNG icons.
// (Replaces the earlier SVG-glyph version. Each item has a high-res 3x PNG
// pin asset; we just drop it in at the requested size.)

const GAME_ITEMS = {
  start: {
    name: 'Start', nameKo: '미션 시작',
    category: 'core', essential: true, transparency: 'normal',
    tint: '#1CB0F6', deep: '#0084C2',
    asset: 'assets/items/i_start.png',
    desc: '획득하면 미션의 시간·퀴즈 등 각종 정보를 볼 수 있어요.',
  },
  end: {
    name: 'End', nameKo: '미션 종료',
    category: 'core', essential: true, transparency: 'normal',
    tint: '#58CC02', deep: '#43A601',
    asset: 'assets/items/i_end.png',
    desc: '필수 아이템을 모두 얻은 뒤 End를 획득하면 미션 완료!',
  },
  hint: {
    name: 'Hint', nameKo: '힌트',
    category: 'core', essential: false, transparency: 'normal',
    tint: '#FFC800', deep: '#D9A800',
    asset: 'assets/items/i_simple.png',
    desc: '미션 퀴즈에 대한 힌트 또는 장소 정보를 볼 수 있어요.',
  },
  mine: {
    name: 'Mine', nameKo: '지뢰',
    category: 'core', essential: false, transparency: 'hidden',
    tint: '#FF4B4B', deep: '#C12626',
    asset: 'assets/items/i_mine.png',
    desc: '반경 안에 들어가면 지뢰가 터져요. 최근 아이템을 잃어요.',
  },
  defence: {
    name: 'Defence', nameKo: '방어',
    category: 'mod', essential: false, transparency: 'normal',
    tint: '#1CB0F6', deep: '#0084C2',
    asset: 'assets/items/i_mine_nobomb.png',
    desc: '획득하면 지뢰 피해를 1회 막아줘요.',
  },
  gambling: {
    name: 'Gambling', nameKo: '복권 상자',
    category: 'mod', essential: false, transparency: 'normal',
    tint: '#FF9600', deep: '#E08600',
    asset: 'assets/items/i_random_box.png',
    desc: '미획득 아이템 중 하나를 랜덤으로 얻어요. (End 제외)',
  },
  quiz: {
    name: 'Quiz', nameKo: '퀴즈',
    category: 'quiz', essential: true, transparency: 'normal',
    tint: '#FF4B4B', deep: '#C12626',
    asset: 'assets/items/i_quiz.png',
    desc: '퀴즈를 풀어야 해요. 오답일 경우 힌트가 나옵니다.',
  },
  solution: {
    name: 'Solution', nameKo: '해답',
    category: 'quiz', essential: false, transparency: 'normal',
    tint: '#1CB0F6', deep: '#0084C2',
    asset: 'assets/items/i_genius.png',
    desc: '획득하면 퀴즈와 미션 퀴즈의 정답을 알려줘요.',
  },
  oxO: {
    name: 'OX · O', nameKo: '정답 O',
    category: 'quiz', essential: false, transparency: 'normal',
    tint: '#58CC02', deep: '#43A601',
    asset: 'assets/items/i_simple.png', // placeholder reuse
    desc: 'OX 퀴즈의 O 보기예요.',
  },
  oxX: {
    name: 'OX · X', nameKo: '정답 X',
    category: 'quiz', essential: false, transparency: 'normal',
    tint: '#FF4B4B', deep: '#C12626',
    asset: 'assets/items/i_simple.png',
    desc: 'OX 퀴즈의 X 보기예요.',
  },
  mapRadar: {
    name: 'Map Radar', nameKo: '지도 레이더',
    category: 'radar', essential: false, transparency: 'normal',
    tint: '#CE82FF', deep: '#8C39C8',
    asset: 'assets/items/i_radar_map.png',
    desc: 'Hidden 속성을 가진 아이템을 지도상에 보여줘요.',
  },
  mineRadar: {
    name: 'Mine Radar', nameKo: '지뢰 레이더',
    category: 'radar', essential: false, transparency: 'normal',
    tint: '#CE82FF', deep: '#8C39C8',
    asset: 'assets/items/i_radar_mine.png',
    desc: 'Mine 아이템의 폭발 반경을 지도에 표시해요.',
  },
  stealthRadar: {
    name: 'Stealth Radar', nameKo: '스텔스 레이더',
    category: 'radar', essential: false, transparency: 'normal',
    tint: '#CE82FF', deep: '#8C39C8',
    asset: 'assets/items/i_radar_ar.png',
    desc: 'Stealth 아이템도 AR 레이더에 보이게 해요.',
  },
  allRadar: {
    name: 'All Radar', nameKo: '전체 레이더',
    category: 'radar', essential: false, transparency: 'normal',
    tint: '#CE82FF', deep: '#8C39C8',
    asset: 'assets/items/i_radar_all.png',
    desc: '모든 종류의 아이템을 지도에 표시해요.',
  },
  runStart: {
    name: 'Run Start', nameKo: '러닝 시작',
    category: 'time', essential: false, transparency: 'normal',
    tint: '#58CC02', deep: '#43A601',
    asset: 'assets/items/i_time_start.png',
    desc: '제한 시간 내에 Run End까지 도달해야 해요.',
  },
  runEnd: {
    name: 'Run End', nameKo: '러닝 끝',
    category: 'time', essential: false, transparency: 'normal',
    tint: '#58CC02', deep: '#43A601',
    asset: 'assets/items/i_time_end.png',
    desc: 'Run Start 후 제한 시간 안에 도달해야 해요.',
  },
  dark: {
    name: 'Dark', nameKo: '암흑 지역',
    category: 'mod', essential: false, transparency: 'normal',
    tint: '#2D3339', deep: '#000',
    asset: 'assets/items/i_black.png',
    desc: '반경 안에서는 모든 아이템이 사라져요. AR로만 찾아야 해요.',
  },
  store: {
    name: 'Store', nameKo: '상점',
    category: 'mod', essential: false, transparency: 'normal',
    tint: '#FFC800', deep: '#E08600',
    asset: 'assets/items/i_store.png',
    desc: '코인으로 아이템을 살 수 있는 장소예요.',
  },
  coupon: {
    name: 'Coupon', nameKo: '쿠폰',
    category: 'mod', essential: false, transparency: 'normal',
    tint: '#FF4B4B', deep: '#C12626',
    asset: 'assets/items/i_coupon.png',
    desc: '특별 보상 쿠폰을 획득해요.',
  },
  hospital: {
    name: 'Hospital', nameKo: '병원',
    category: 'mod', essential: false, transparency: 'normal',
    tint: '#FF4B4B', deep: '#C12626',
    asset: 'assets/items/i_simple.png',
    desc: '체력 회복 — 잃어버린 아이템을 한 번 되찾아요.',
  },
};

// Pin component — renders the PNG asset as the pin body, optional glow.
function ItemPin({ kind = 'quiz', size = 44, active, glow, dimmed }) {
  const k = GAME_ITEMS[kind];
  if (!k) return null;
  // Aspect ratio: pin assets are roughly 1:1.25 (with the tail). Render
  // as a slightly taller box so the tail isn't cropped.
  const w = size, h = size * 1.2;
  return (
    <div style={{
      position: 'relative',
      width: w, height: h,
      opacity: dimmed ? 0.5 : 1,
      filter: dimmed ? 'grayscale(0.6)' : 'none',
      pointerEvents: 'none',
    }}>
      {glow && (
        <div style={{
          position: 'absolute', inset: -size * 0.35,
          background: `radial-gradient(circle, ${k.tint}55 0%, transparent 65%)`,
          borderRadius: '50%',
        }} />
      )}
      <img src={k.asset} alt={k.name}
        style={{
          width: '100%', height: '100%',
          objectFit: 'contain',
          display: 'block',
          filter: 'drop-shadow(0 2px 2px rgba(0,0,0,0.25))',
        }}
        draggable={false}/>
      {/* Essential star overlay — uses the same yellow circle motif as the assets */}
      {active && (
        <svg width={size*0.42} height={size*0.42}
          viewBox="0 0 24 24"
          style={{ position: 'absolute', top: -size*0.04, right: -size*0.04 }}>
          <circle cx="12" cy="12" r="10" fill="#FFC800" stroke="#fff" strokeWidth="2"/>
          <path d="M12 6 L14 11 L19 11 L15 14 L17 19 L12 16 L7 19 L9 14 L5 11 L10 11 Z" fill="#fff"/>
        </svg>
      )}
    </div>
  );
}

Object.assign(window, { GAME_ITEMS, ItemPin });
