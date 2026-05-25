// PlaySpot — newly added meta/profile screens (v2 redesign)
// Based on the latest iOS screenshots: Settings, My Info, Badge List (5-tab nav)

// ─────────────────────────────────────────────────────────────
// SCREEN: Settings
// ─────────────────────────────────────────────────────────────
function ScreenSettings({ onNav, onHowToPlay }) {
  return (
    <div className="ps-screen">
      <PSStatusBar/>

      <div style={{ flex: 1, overflow: 'auto', padding: '4px 16px 16px', background: 'var(--duo-snow)' }}>
        <div className="ps-display" style={{ fontSize: 28, color: 'var(--duo-eel-2)', margin: '6px 0 14px' }}>
          Settings
        </div>

        <FormGroup title="ACCOUNT">
          <FormRow label="User ID" value="Guest@0525072819861" muted/>
          <FormRow label="Login" tint="blue" link isLast/>
        </FormGroup>

        <FormGroup title="API BACKEND" subtitle="REST 로 전환 시 다음 호출부터 /api/v1/** 사용. 재로그인 필요.">
          <div style={{ padding: 10 }}>
            <div style={{
              display: 'grid', gridTemplateColumns: '1fr 1fr',
              background: 'var(--duo-snow)', border: '1.5px solid var(--duo-swan)',
              borderRadius: 10, padding: 3, gap: 3,
            }}>
              <SegBtn>Legacy</SegBtn>
              <SegBtn active>REST</SegBtn>
            </div>
          </div>
        </FormGroup>

        <FormGroup title="DEBUG — 401 자동 재로그인 검증" subtitle="Console 로그에서 'auto re-login' 출력 확인.">
          <FormRow label="Simulate 401: token 손상 + fetch 시도" tint="blue" link isLast/>
        </FormGroup>

        <FormGroup title="TUTORIAL">
          <FormRow label="How to Play" tint="blue" link onClick={onHowToPlay} isLast/>
        </FormGroup>

        <FormGroup title="ABOUT">
          <FormRow label="Version" value="1.0"/>
          <FormRow label="Build" value="1" isLast/>
        </FormGroup>
      </div>

      <BottomNav5 active="settings" onNav={onNav}/>
    </div>
  );
}

function SegBtn({ children, active }) {
  return (
    <div style={{
      height: 30, borderRadius: 8,
      background: active ? '#fff' : 'transparent',
      border: active ? '1px solid var(--duo-green-800)' : '1px solid transparent',
      boxShadow: active ? '0 1px 0 0 var(--duo-green-800)' : 'none',
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      fontFamily: 'var(--font-display)', fontWeight: 900, fontSize: 11,
      color: active ? 'var(--duo-green-900)' : 'var(--duo-wolf-2)',
      letterSpacing: '0.04em',
    }}>{children}</div>
  );
}

// Reusable rounded group + rows (iOS card form translated to Duo style)
function FormGroup({ title, subtitle, children }) {
  return (
    <div style={{ marginBottom: 14 }}>
      {title && (
        <div className="ps-cap" style={{
          fontSize: 10, color: 'var(--duo-hare)',
          marginBottom: 6, paddingLeft: 4, letterSpacing: '0.06em',
        }}>{title}</div>
      )}
      <div style={{
        background: '#fff',
        border: '2px solid var(--duo-swan-2)',
        borderRadius: 14,
        boxShadow: '0 2px 0 0 var(--duo-swan-2)',
        overflow: 'hidden',
      }}>
        {children}
      </div>
      {subtitle && (
        <div style={{
          fontSize: 11, color: 'var(--duo-hare)',
          marginTop: 6, paddingLeft: 4, lineHeight: 1.4,
        }}>{subtitle}</div>
      )}
    </div>
  );
}

function FormRow({ label, value, tint, link, onClick, isLast, muted }) {
  const color = tint === 'blue' ? 'var(--duo-macaw)'
              : tint === 'red'  ? 'var(--duo-cardinal)'
              : 'var(--duo-eel-2)';
  return (
    <div onClick={onClick} style={{
      display: 'flex', alignItems: 'center', gap: 10,
      padding: '12px 14px',
      borderBottom: isLast ? 'none' : '1px solid var(--duo-swan)',
      cursor: link ? 'pointer' : 'default',
    }}>
      <div style={{
        flex: 1, fontFamily: 'var(--font-display)', fontWeight: link ? 900 : 800,
        fontSize: 14, color,
      }}>{label}</div>
      {value && (
        <div style={{
          fontFamily: 'var(--font-body)', fontWeight: 600,
          fontSize: 13, color: muted ? 'var(--duo-hare)' : 'var(--duo-wolf-2)',
        }}>{value}</div>
      )}
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// SCREEN: My Info
// ─────────────────────────────────────────────────────────────
function ScreenMyInfo({ onNav }) {
  return (
    <div className="ps-screen">
      <PSStatusBar/>
      <div style={{ flex: 1, overflow: 'auto', padding: '4px 16px 16px', background: 'var(--duo-snow)' }}>
        <div className="ps-display" style={{ fontSize: 28, color: 'var(--duo-eel-2)', margin: '6px 0 14px' }}>
          My Info
        </div>

        {/* Profile card */}
        <div style={{
          display: 'flex', alignItems: 'center', gap: 12,
          background: '#fff', border: '2px solid var(--duo-swan-2)',
          borderRadius: 14, boxShadow: '0 2px 0 0 var(--duo-swan-2)',
          padding: 12, marginBottom: 16,
        }}>
          <div style={{
            width: 50, height: 50, borderRadius: '50%',
            background: 'var(--duo-macaw)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            boxShadow: '0 2px 0 0 #0084c2',
          }}>
            <PSIcons.User size={26} color="#fff"/>
          </div>
          <div style={{ flex: 1 }}>
            <div style={{ fontFamily: 'var(--font-display)', fontWeight: 900, fontSize: 16, color: 'var(--duo-eel-2)' }}>
              test@gmail.com
            </div>
            <div style={{ fontSize: 12, color: 'var(--duo-hare)', marginTop: 2 }}>Member</div>
          </div>
        </div>

        <FormGroup title="ITEMS">
          <FormRow label="Solutions" value="0"/>
          <FormRow label="Time Add" value="0" isLast/>
        </FormGroup>

        <FormGroup title="DESIGNED (3)">
          <FormRow label="다수아이템 배치 테스트" link/>
          <FormRow label="dd" link/>
          <FormRow label="테스트" link isLast/>
        </FormGroup>

        <FormGroup title="PLAYED (2)">
          <FormRow label="타임 런 미션" link/>
          <FormRow label="맵 레이더 & 갬블링 미션" link isLast/>
        </FormGroup>
      </div>

      <BottomNav5 active="info" onNav={onNav}/>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// SCREEN: Badge List (5-tab nav, sectioned green/teal header)
// ─────────────────────────────────────────────────────────────
function ScreenBadgeListV2({ onNav }) {
  return (
    <div className="ps-screen">
      <PSStatusBar/>
      <div style={{ padding: '6px 16px 12px', textAlign: 'center' }}>
        <div style={{ fontFamily: 'var(--font-display)', fontWeight: 900, fontSize: 17, color: 'var(--duo-eel-2)' }}>
          Badge List
        </div>
      </div>

      <div style={{ flex: 1, overflow: 'auto', padding: '0 16px 16px', background: 'var(--duo-snow)' }}>
        {/* Mission Badge group */}
        <BadgeSection title="Mission Badge" tint="teal">
          <BadgeCellV2 unlocked label="타임 런 미션" color="#FFC800" icon={<PSIcons.Bolt size={28}/>}/>
          <BadgeCellV2 unlocked label="맵 레이더 & 갬블링 미션" color="#CE82FF" icon={<PSIcons.Gem size={28}/>}/>
          <BadgeCellV2 label="???"/>
          <BadgeCellV2 label="???"/>
          <BadgeCellV2 label="???"/>
          <BadgeCellV2 label="???"/>
        </BadgeSection>

        {/* Play Badge group */}
        <BadgeSection title="Play Badge" tint="teal">
          <BadgeCellV2 unlocked label="1" color="#8EE000" icon={
            <div style={{
              fontFamily: 'var(--font-display)', fontWeight: 900, fontSize: 22, color: '#fff',
              textShadow: '0 2px 0 #3a8a02',
            }}>play 1</div>
          }/>
          <BadgeCellV2 label="5"/>
          <BadgeCellV2 label="10"/>
          <BadgeCellV2 label="15"/>
          <BadgeCellV2 label="20"/>
          <BadgeCellV2 label="25"/>
        </BadgeSection>
      </div>

      <BottomNav5 active="badge" onNav={onNav}/>
    </div>
  );
}

function BadgeSection({ title, tint = 'teal', children }) {
  const bg = tint === 'teal' ? '#1c8a9f' : 'var(--duo-green-500)';
  const deep = tint === 'teal' ? '#0e6675' : 'var(--duo-green-700)';
  return (
    <div style={{
      background: '#fff',
      border: '2px solid var(--duo-swan-2)',
      borderRadius: 14,
      boxShadow: '0 2px 0 0 var(--duo-swan-2)',
      marginBottom: 14, overflow: 'hidden',
    }}>
      <div style={{
        background: bg, padding: '10px 14px',
        boxShadow: `inset 0 -2px 0 0 ${deep}`,
        fontFamily: 'var(--font-display)', fontWeight: 900, fontSize: 14,
        color: '#fff', letterSpacing: '0.02em',
      }}>{title}</div>
      <div style={{
        display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 6,
        padding: 10,
      }}>
        {children}
      </div>
    </div>
  );
}

function BadgeCellV2({ unlocked, label, color, icon }) {
  return (
    <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 4 }}>
      <div style={{
        width: 60, height: 60, borderRadius: '50%',
        background: unlocked ? color : '#bcbcbc',
        border: `2.5px solid ${unlocked ? '#2D3339' : '#888'}`,
        boxShadow: unlocked ? '0 3px 0 0 rgba(0,0,0,0.2)' : '0 2px 0 0 rgba(0,0,0,0.15)',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        position: 'relative', overflow: 'hidden',
        filter: unlocked ? 'none' : 'saturate(0)',
      }}>
        {unlocked ? icon : (
          <div style={{ fontFamily: 'var(--font-display)', fontWeight: 900, fontSize: 28, color: '#fff', opacity: 0.65 }}>?</div>
        )}
      </div>
      <div style={{
        fontFamily: 'var(--font-display)', fontWeight: 800, fontSize: 10,
        color: unlocked ? 'var(--duo-eel-2)' : 'var(--duo-hare)',
        textAlign: 'center', lineHeight: 1.2,
      }}>{label}</div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// 5-tab bottom nav: Missions / Design / My Info / Badge / Settings
// ─────────────────────────────────────────────────────────────
function BottomNav5({ active, onNav }) {
  const tabs = [
    { id: 'list',     icon: <PSIcons.List size={22}/>,   label: 'Missions' },
    { id: 'design',   icon: <PSIcons.Pencil size={22}/>, label: 'Design' },
    { id: 'info',     icon: <PSIcons.User size={22}/>,   label: 'My Info' },
    { id: 'badge',    icon: <PSIcons.Badge size={22}/>,  label: 'Badge' },
    { id: 'settings', icon: <PSIcons.Settings size={22}/>, label: 'Settings' },
  ];
  // Map "info"/"settings" etc → active id
  return (
    <div className="ps-nav">
      {tabs.map(t => {
        const isActive = active === t.id;
        return (
          <div key={t.id} className={`ps-nav-item ${isActive ? 'active' : ''}`} onClick={() => onNav?.(t.id)}>
            <div style={{ color: isActive ? 'var(--duo-macaw)' : 'var(--duo-hare)' }}>{t.icon}</div>
            <div style={{ fontSize: 9 }}>{t.label}</div>
          </div>
        );
      })}
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// SCREEN: Item Detail v2 — clean iOS-form layout (Mine variant)
// ─────────────────────────────────────────────────────────────
function ScreenItemDetailV2({ kind = 'mine', onDone, onCancel, onDelete }) {
  const item = GAME_ITEMS[kind] || GAME_ITEMS.mine;
  const [mandatory, setMandatory] = React.useState(item.essential);
  const [range, setRange] = React.useState(45);

  // Per-item tip line
  const tipMap = {
    mine: '반경(rangeAR)만 설정하면 끝. 좁은 길목·핵심 동선에 두면 긴장감이 살아납니다. 지도에 빨간 원으로 표시돼요.',
    hint: '미션 진행에 결정적인 단서를 적어주세요. 너무 친절하면 재미가 떨어져요.',
    quiz: 'OX 또는 단답형 문제를 적어주세요. 오답 시 힌트가 노출돼요.',
    runEnd: 'Run Start와 함께 두면 러닝 미니게임이 활성화됩니다.',
  };
  const tip = tipMap[kind] || '아이템 정보를 설정해주세요.';

  return (
    <div className="ps-screen">
      <PSStatusBar/>

      {/* Top nav: 취소 / 아이템 상세 / 완료 */}
      <div style={{
        padding: '6px 16px 12px',
        display: 'flex', alignItems: 'center', justifyContent: 'space-between',
      }}>
        <button onClick={onCancel} style={{
          background: 'none', border: 'none', cursor: 'pointer',
          color: 'var(--duo-macaw)', fontFamily: 'var(--font-display)',
          fontWeight: 800, fontSize: 14, padding: 0,
        }}>취소</button>
        <div style={{
          fontFamily: 'var(--font-display)', fontWeight: 900,
          fontSize: 16, color: 'var(--duo-eel-2)',
        }}>아이템 상세</div>
        <button onClick={onDone} style={{
          background: 'none', border: 'none', cursor: 'pointer',
          color: 'var(--duo-macaw)', fontFamily: 'var(--font-display)',
          fontWeight: 900, fontSize: 14, padding: 0,
        }}>완료</button>
      </div>

      <div style={{ flex: 1, overflow: 'auto', padding: '0 14px 16px', background: 'var(--duo-snow)' }}>
        {/* 아이템 정보 */}
        <div className="ps-cap" style={{ fontSize: 10, color: 'var(--duo-hare)', marginBottom: 6, paddingLeft: 4 }}>
          아이템 정보
        </div>
        <div style={{
          background: '#fff', border: '2px solid var(--duo-swan-2)',
          borderRadius: 14, boxShadow: '0 2px 0 0 var(--duo-swan-2)',
          padding: 14, marginBottom: 14,
          display: 'flex', gap: 14, alignItems: 'flex-start',
        }}>
          <div style={{ flex: 'none' }}>
            <ItemPin kind={kind} size={56}/>
          </div>
          <div style={{ flex: 1, minWidth: 0 }}>
            <div style={{
              fontFamily: 'var(--font-display)', fontWeight: 900,
              fontSize: 18, color: 'var(--duo-eel-2)',
            }}>{item.name}</div>
            <div style={{
              fontSize: 12, color: 'var(--duo-wolf-2)', marginTop: 4,
              lineHeight: 1.5,
            }}>{item.desc}</div>
          </div>
        </div>

        {/* Tip card */}
        <div style={{
          background: 'var(--duo-bee-bg)',
          border: '2px solid #e8c878',
          borderRadius: 12,
          boxShadow: '0 2px 0 0 #e8c878',
          padding: '10px 12px',
          marginBottom: 16,
          display: 'flex', gap: 8, alignItems: 'flex-start',
        }}>
          <div style={{ fontSize: 16, flex: 'none', marginTop: -1 }}>💡</div>
          <div style={{ fontSize: 12, color: 'var(--duo-eel-2)', lineHeight: 1.5, flex: 1 }}>
            {tip}
          </div>
        </div>

        {/* MINE (지뢰) section */}
        <div className="ps-cap" style={{ fontSize: 10, color: 'var(--duo-hare)', marginBottom: 6, paddingLeft: 4 }}>
          {item.name.toUpperCase()} ({item.nameKo})
        </div>
        <div style={{
          background: '#fff', border: '2px solid var(--duo-swan-2)',
          borderRadius: 14, boxShadow: '0 2px 0 0 var(--duo-swan-2)',
          marginBottom: 14, overflow: 'hidden',
        }}>
          {/* 필수 여부 */}
          <div style={{
            padding: '12px 14px',
            borderBottom: '1px solid var(--duo-swan)',
          }}>
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
              <div style={{
                fontFamily: 'var(--font-display)', fontWeight: 900,
                fontSize: 14, color: 'var(--duo-eel-2)',
              }}>필수 여부</div>
              <div style={{
                fontFamily: 'var(--font-display)', fontWeight: 800,
                fontSize: 12, color: 'var(--duo-hare)',
              }}>자동 — {mandatory ? '켜짐' : '꺼짐'}</div>
            </div>
            <div style={{ fontSize: 11, color: 'var(--duo-hare)', marginTop: 2 }}>
              이 아이템은 미션 완료에 영향을 주지 않아요.
            </div>
          </div>

          {/* 발견 거리 */}
          <div style={{
            padding: '12px 14px',
            borderBottom: '1px solid var(--duo-swan)',
          }}>
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 10 }}>
              <div style={{
                fontFamily: 'var(--font-display)', fontWeight: 900,
                fontSize: 14, color: 'var(--duo-eel-2)',
              }}>발견 거리: {range} m</div>
              <Stepper value={range} onChange={setRange}/>
            </div>
            <div style={{ fontSize: 11, color: 'var(--duo-hare)', marginTop: 4 }}>
              AR 화면에서 아이템이 표시되는 유효 반경.
            </div>
          </div>

          {/* 폭발 반경 (mine only) */}
          {kind === 'mine' && (
            <div style={{ padding: '12px 14px' }}>
              <div style={{
                fontFamily: 'var(--font-display)', fontWeight: 900,
                fontSize: 13, color: 'var(--duo-fox)',
              }}>폭발 반경: {range} m</div>
            </div>
          )}
        </div>

        {/* Delete button */}
        <button onClick={onDelete} style={{
          width: '100%',
          background: '#fff',
          border: '2px solid var(--duo-swan-2)',
          borderRadius: 14,
          boxShadow: '0 2px 0 0 var(--duo-swan-2)',
          padding: '14px',
          display: 'flex', alignItems: 'center', gap: 12,
          cursor: 'pointer',
        }}>
          <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="var(--duo-macaw)" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
            <polyline points="3 6 5 6 21 6"/>
            <path d="M19 6l-2 14H7L5 6"/>
            <path d="M10 11v6M14 11v6"/>
            <path d="M9 6V4h6v2"/>
          </svg>
          <div style={{
            fontFamily: 'var(--font-display)', fontWeight: 900,
            fontSize: 15, color: 'var(--duo-cardinal)',
          }}>아이템 삭제</div>
        </button>
      </div>
    </div>
  );
}

function Stepper({ value, onChange, step = 5, min = 5, max = 200 }) {
  return (
    <div style={{
      display: 'flex', alignItems: 'center',
      background: 'var(--duo-snow)',
      border: '1.5px solid var(--duo-swan)',
      borderRadius: 999, overflow: 'hidden', height: 30,
    }}>
      <button onClick={() => onChange(Math.max(min, value - step))} style={{
        width: 36, height: 30, background: 'none', border: 'none',
        fontFamily: 'var(--font-display)', fontWeight: 900, fontSize: 16,
        color: 'var(--duo-wolf-2)', cursor: 'pointer',
      }}>−</button>
      <div style={{ width: 1, height: 14, background: 'var(--duo-swan)' }}/>
      <button onClick={() => onChange(Math.min(max, value + step))} style={{
        width: 36, height: 30, background: 'none', border: 'none',
        fontFamily: 'var(--font-display)', fontWeight: 900, fontSize: 16,
        color: 'var(--duo-wolf-2)', cursor: 'pointer',
      }}>+</button>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// SCREEN: Design List v2 — sectioned (비공개/공개)
// ─────────────────────────────────────────────────────────────
function ScreenDesignListV2({ onBack, onNew, onPick, onNav }) {
  const privateDesigns = [
    { title: 'dd', desc: 'dd', loc: null },
    { title: '테스트', desc: '경기도 부천시 역곡동 역곡동', loc: '경기도 부천시 역곡동 역곡동' },
  ];
  const publicDesigns = [
    { title: '다수아이템 배치 테스트', desc: '경기도 부천시 역곡동 지봉로70번길', loc: '경기도 부천시 역곡동 지봉로70번길' },
  ];

  return (
    <div className="ps-screen">
      <PSStatusBar/>

      {/* Top: + button */}
      <div style={{
        padding: '6px 16px 0',
        display: 'flex', alignItems: 'center', justifyContent: 'flex-end',
      }}>
        <button onClick={onNew} style={{
          width: 36, height: 36, borderRadius: 10,
          background: 'var(--duo-green-500)', border: '1.5px solid var(--duo-green-800)',
          boxShadow: '0 2px 0 0 var(--duo-green-700)',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          cursor: 'pointer', padding: 0,
        }}>
          <PSIcons.Plus size={20} color="#fff"/>
        </button>
      </div>

      <div style={{ padding: '0 16px 8px' }}>
        <div className="ps-display" style={{ fontSize: 28, color: 'var(--duo-eel-2)' }}>
          내 디자인
        </div>
      </div>

      <div style={{ flex: 1, overflow: 'auto', padding: '6px 16px 16px', background: 'var(--duo-snow)' }}>
        {/* 비공개 */}
        <div className="ps-cap" style={{ fontSize: 10, color: 'var(--duo-hare)', marginBottom: 6, paddingLeft: 4 }}>
          비공개
        </div>
        <div style={{
          background: '#fff', border: '2px solid var(--duo-swan-2)',
          borderRadius: 14, boxShadow: '0 2px 0 0 var(--duo-swan-2)',
          marginBottom: 14, overflow: 'hidden',
        }}>
          {privateDesigns.map((d, i) => (
            <DesignRowV2 key={i} d={d} status="비공개" onClick={() => onPick?.(d)} isLast={i === privateDesigns.length - 1}/>
          ))}
        </div>

        {/* 공개 */}
        <div className="ps-cap" style={{ fontSize: 10, color: 'var(--duo-hare)', marginBottom: 6, paddingLeft: 4 }}>
          공개
        </div>
        <div style={{
          background: '#fff', border: '2px solid var(--duo-swan-2)',
          borderRadius: 14, boxShadow: '0 2px 0 0 var(--duo-swan-2)',
          marginBottom: 8, overflow: 'hidden',
        }}>
          {publicDesigns.map((d, i) => (
            <DesignRowV2 key={i} d={d} status="공개" onClick={() => onPick?.(d)} isLast={i === publicDesigns.length - 1}/>
          ))}
        </div>
        <div style={{ fontSize: 11, color: 'var(--duo-hare)', paddingLeft: 4, lineHeight: 1.4 }}>
          공개된 미션은 바로 삭제할 수 없어요. 먼저 '공개 해제' 한 뒤 비공개 목록에서 삭제하세요.
        </div>
      </div>

      <BottomNav5 active="design" onNav={onNav}/>
    </div>
  );
}

function DesignRowV2({ d, status, onClick, isLast }) {
  const isPublic = status === '공개';
  return (
    <div onClick={onClick} style={{
      display: 'flex', alignItems: 'center', gap: 10,
      padding: '12px 14px',
      borderBottom: isLast ? 'none' : '1px solid var(--duo-swan)',
      cursor: 'pointer',
    }}>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{
          fontFamily: 'var(--font-display)', fontWeight: 900,
          fontSize: 15, color: 'var(--duo-eel-2)',
        }}>{d.title}</div>
        <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginTop: 4 }}>
          <span className="ps-chip" style={{
            background: isPublic ? 'var(--duo-green-100)' : 'var(--duo-fox-bg)',
            color: isPublic ? 'var(--duo-green-800)' : '#a55e00',
            height: 18, padding: '0 8px', fontSize: 9,
          }}>{status}</span>
          <span style={{ fontSize: 11, color: 'var(--duo-wolf-2)',
            whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis',
          }}>{d.desc}</span>
        </div>
      </div>
      <div style={{
        display: 'flex', alignItems: 'center', gap: 4, flex: 'none',
      }}>
        <div style={{
          width: 26, height: 26, borderRadius: '50%',
          background: 'var(--duo-green-500)',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          boxShadow: '0 1px 0 0 var(--duo-green-700)',
        }}>
          <svg width="12" height="12" viewBox="0 0 24 24" fill="#fff"><path d="M8 5v14l11-7z"/></svg>
        </div>
        <div style={{
          fontFamily: 'var(--font-display)', fontWeight: 900,
          fontSize: 12, color: 'var(--duo-green-800)',
        }}>테스트</div>
        <svg width="10" height="14" viewBox="0 0 8 14" fill="none" stroke="var(--duo-hare)" strokeWidth="2">
          <polyline points="1 1 7 7 1 13"/>
        </svg>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// SCREEN: Mission Edit v2 (matches latest iOS form layout)
// ─────────────────────────────────────────────────────────────
function ScreenMissionEditV2({ onCancel, onSave, onNav }) {
  const [timeLimit, setTimeLimit] = React.useState(false);
  const [virtual, setVirtual] = React.useState(true);

  return (
    <div className="ps-screen">
      <PSStatusBar/>

      <div style={{
        padding: '6px 16px 12px',
        display: 'flex', alignItems: 'center', justifyContent: 'space-between',
      }}>
        <button onClick={onCancel} style={{
          background: 'none', border: 'none', cursor: 'pointer',
          color: 'var(--duo-macaw)', fontFamily: 'var(--font-display)',
          fontWeight: 800, fontSize: 14, padding: 0,
          display: 'flex', alignItems: 'center', gap: 2,
        }}>
          <svg width="10" height="14" viewBox="0 0 8 14" fill="none" stroke="currentColor" strokeWidth="2.5">
            <polyline points="7 1 1 7 7 13"/>
          </svg>
          내 디자인 취소
        </button>
        <button onClick={onSave} style={{
          background: 'none', border: 'none', cursor: 'pointer',
          color: 'var(--duo-macaw)', fontFamily: 'var(--font-display)',
          fontWeight: 900, fontSize: 14, padding: 0,
        }}>저장</button>
      </div>

      <div style={{ flex: 1, overflow: 'auto', padding: '0 16px 16px', background: 'var(--duo-snow)' }}>
        <div className="ps-display" style={{ fontSize: 28, color: 'var(--duo-eel-2)', margin: '4px 0 16px' }}>
          미션 편집
        </div>

        {/* 기본 정보 */}
        <FormGroup title="기본 정보">
          <FieldRow value="다수아이템 배치 테스트"/>
          <FieldRow value="경기도 부천시 역곡동 지봉로70번길"/>
          <FieldRow value="좌표로 장소 자동 채우기" tint="blue" icon={
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="var(--duo-macaw)" strokeWidth="2.5">
              <circle cx="11" cy="11" r="7"/><line x1="21" y1="21" x2="16.65" y2="16.65"/>
            </svg>
          } isLast/>
        </FormGroup>

        {/* 설명 */}
        <FormGroup title="설명">
          <div style={{ padding: 12, minHeight: 100, fontSize: 14, color: 'var(--duo-eel-2)' }}>
            er
          </div>
        </FormGroup>

        {/* 플레이 제한 시간 */}
        <FormGroup title="플레이 제한 시간" subtitle="시간 제한 없음 — 경과 시간만 표시됩니다.">
          <div style={{
            padding: '12px 14px',
            display: 'flex', alignItems: 'center', justifyContent: 'space-between',
          }}>
            <div style={{
              fontFamily: 'var(--font-display)', fontWeight: 900,
              fontSize: 14, color: 'var(--duo-eel-2)',
            }}>시간 제한</div>
            <PSToggle on={timeLimit} onChange={setTimeLimit}/>
          </div>
        </FormGroup>

        {/* 플레이 설정 */}
        <FormGroup title="플레이 설정">
          <div style={{
            padding: '12px 14px',
            display: 'flex', alignItems: 'center', justifyContent: 'space-between',
            borderBottom: '1px solid var(--duo-swan)',
          }}>
            <div style={{
              fontFamily: 'var(--font-display)', fontWeight: 900,
              fontSize: 14, color: 'var(--duo-eel-2)',
            }}>Virtual 모드 허용</div>
            <PSToggle on={virtual} onChange={setVirtual}/>
          </div>
          <div style={{
            padding: '12px 14px',
            display: 'flex', alignItems: 'center', justifyContent: 'space-between',
          }}>
            <div style={{
              fontFamily: 'var(--font-display)', fontWeight: 900,
              fontSize: 14, color: 'var(--duo-eel-2)',
            }}>언어</div>
            <div style={{ display: 'flex', alignItems: 'center', gap: 4, color: 'var(--duo-hare)' }}>
              <svg width="10" height="14" viewBox="0 0 14 18" fill="none" stroke="currentColor" strokeWidth="1.8">
                <polyline points="3 7 7 3 11 7"/>
                <polyline points="3 11 7 15 11 11"/>
              </svg>
            </div>
          </div>
        </FormGroup>
      </div>

      <BottomNav5 active="design" onNav={onNav}/>
    </div>
  );
}

function FieldRow({ value, tint, icon, isLast }) {
  return (
    <div style={{
      padding: '12px 14px',
      borderBottom: isLast ? 'none' : '1px solid var(--duo-swan)',
      display: 'flex', alignItems: 'center', gap: 8,
    }}>
      {icon}
      <div style={{
        flex: 1,
        fontFamily: 'var(--font-display)', fontWeight: tint === 'blue' ? 900 : 800,
        fontSize: 14,
        color: tint === 'blue' ? 'var(--duo-macaw)' : 'var(--duo-eel-2)',
      }}>{value}</div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// Item Acquired popup — large white modal w/ PlaySpot logo + orange OK
// ─────────────────────────────────────────────────────────────
function ItemAcquiredPopup({ itemKind = 'start', title = 'Start Item acquired!', body = 'If you touch OK, the item will be released Mission.', onConfirm }) {
  return (
    <div style={{
      position: 'absolute', inset: 0, zIndex: 100,
      background: 'rgba(20,15,12,0.55)',
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      padding: 24,
    }}>
      <div style={{
        width: '100%', maxWidth: 280,
        background: '#fff',
        borderRadius: 18,
        boxShadow: '0 8px 30px rgba(0,0,0,0.4), 0 4px 0 0 var(--duo-swan-2)',
        border: '2px solid var(--duo-swan-2)',
        overflow: 'hidden',
        display: 'flex', flexDirection: 'column',
      }}>
        {/* Logo header */}
        <div style={{
          padding: '20px 16px 12px',
          display: 'flex', justifyContent: 'center',
          borderBottom: '1px solid var(--duo-swan)',
        }}>
          <img src="assets/minigame/playspot_logo.png" alt="PLAY SPOT"
            style={{ height: 56, objectFit: 'contain' }}/>
        </div>

        {/* Item + title */}
        <div style={{
          padding: '16px 14px',
          display: 'flex', alignItems: 'center', gap: 12,
        }}>
          <ItemPin kind={itemKind} size={48}/>
          <div style={{
            fontFamily: 'var(--font-display)', fontWeight: 900,
            fontSize: 16, color: 'var(--duo-eel-2)',
          }}>{title}</div>
        </div>

        {/* Body */}
        <div style={{
          padding: '0 16px 18px', textAlign: 'center',
          fontSize: 13, color: 'var(--duo-wolf-2)', lineHeight: 1.5,
        }}>{body}</div>

        {/* Orange OK */}
        <button onClick={onConfirm} style={{
          background: 'var(--duo-fox)',
          border: 'none',
          padding: '14px',
          fontFamily: 'var(--font-display)', fontWeight: 900,
          fontSize: 16, color: '#fff', letterSpacing: '0.04em',
          cursor: 'pointer',
          boxShadow: 'inset 0 -2px 0 0 var(--duo-fox-deep)',
        }}>OK</button>
      </div>
    </div>
  );
}

Object.assign(window, {
  ScreenSettings, ScreenMyInfo, ScreenBadgeListV2,
  ScreenItemDetailV2, ScreenDesignListV2, ScreenMissionEditV2,
  ItemAcquiredPopup, BottomNav5,
});
