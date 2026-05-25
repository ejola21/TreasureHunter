// PlaySpot — main app. Design canvas hosting:
//   1) "Interactive Prototype" artboard — one iPhone where you can navigate
//      between all screens via real taps. Default landing.
//   2) "In-Game Screens" — every in-mission screen side by side.
//   3) "Meta Screens" — list, edit, badges, tutorial pages side by side.
//
// Tweaks panel exposes color theme + a quick screen jumper.

const SCREENS = [
  { id: 'list',         label: 'Mission List',   group: 'Meta' },
  { id: 'map-play',     label: 'Map — Playing',  group: 'In-game' },
  { id: 'ar-search',    label: 'AR — Searching', group: 'In-game' },
  { id: 'ar-touch',     label: 'AR — Touch',     group: 'In-game' },
  { id: 'ar-party',     label: 'AR — Found',     group: 'In-game' },
  { id: 'hint',         label: 'Hint Popup',     group: 'In-game' },
  { id: 'map-edit',     label: 'Map — Editing',  group: 'Meta' },
  { id: 'badges',       label: 'Badges',         group: 'Meta' },
  { id: 'design-list',  label: 'Design · My Missions',  group: 'Design' },
  { id: 'design-action',label: 'Design · Action Sheet', group: 'Design' },
  { id: 'mission-info', label: 'Design · Test-Play Preview', group: 'Design' },
  { id: 'mission-settings', label: 'Design · Settings Form', group: 'Design' },
  { id: 'item-detail-hint', label: 'Item Detail · Hint',  group: 'Design' },
  { id: 'item-detail-quiz', label: 'Item Detail · Quiz',  group: 'Design' },
  { id: 'item-detail-runEnd', label: 'Item Detail · Run End',  group: 'Design' },
  { id: 'item-detail-mine', label: 'Item Detail · Mine',  group: 'Design' },
  { id: 'map-edit-picker', label: 'Map Edit · Item Picker', group: 'Design' },
  { id: 'design-list-v2', label: 'Design List v2',  group: 'Design' },
  { id: 'mission-edit-v2', label: 'Mission Edit v2', group: 'Design' },
  { id: 'item-detail-v2',  label: 'Item Detail v2 (Mine)', group: 'Design' },
  { id: 'settings',  label: 'Settings',  group: 'Meta' },
  { id: 'my-info',   label: 'My Info',   group: 'Meta' },
  { id: 'badges-v2', label: 'Badges v2', group: 'Meta' },
  { id: 'item-acquired', label: 'Map Play · Item Acquired', group: 'In-game' },
  { id: 'help-items',   label: 'Help · Items',   group: 'Help' },
  { id: 'help-howto',   label: 'Help · How to Play', group: 'Help' },
  { id: 'help-design',  label: 'Help · Design',  group: 'Help' },
  { id: 'tutorial',     label: 'Onboarding',     group: 'Meta' },
];

const TWEAK_DEFAULTS = /*EDITMODE-BEGIN*/{
  "accent": "green",
  "screen": "list",
  "dark": false,
  "font": "jalnan",
  "mascot": true,
  "speed": 1,
  "showHints": true
}/*EDITMODE-END*/;

// Pick a screen by id with appropriate handlers wired in
function RenderScreen({ id, setScreen, tutStep, setTutStep, tab, setTab }) {
  // Help-tab cross-navigation: tapping the segmented tabs jumps between
  // the three Help pages without leaving the bottom-nav HELP context.
  const onHelpTab = (t) => {
    if (t === 'items')  setScreen('help-items');
    if (t === 'howto')  setScreen('help-howto');
    if (t === 'design') setScreen('help-design');
  };
  const onHelpNav = (t) => {
    if (t === 'list')   setScreen('list');
    else if (t === 'badge')  setScreen('badges');
    else if (t === 'design') setScreen('map-edit');
    else if (t === 'help')   setScreen('help-items');
  };

  switch (id) {
    case 'list':
      return <ScreenMissionList tab={tab} onTab={setTab}
        onMission={() => setScreen('mission-info')}
        onNav={(t) => {
          if (t === 'badge')       setScreen('badges');
          else if (t === 'design') setScreen('design-list');
          else if (t === 'help')   setScreen('help-items');
        }}/>;
    case 'map-play':
      return <ScreenMapPlay
        onCamera={() => setScreen('ar-search')}
        onExit={() => setScreen('list')}/>;
    case 'ar-search':
      return <ScreenARSearch onMap={() => setScreen('map-play')}/>;
    case 'ar-touch':
      return <ScreenARFound variant="touch"
        onMap={() => setScreen('map-play')}
        onTap={() => setScreen('hint')}/>;
    case 'ar-party':
      return <ScreenARFound variant="party"
        onMap={() => setScreen('map-play')}
        onTap={() => setScreen('hint')}/>;
    case 'hint':
      return <ScreenHintPopup
        onConfirm={() => setScreen('ar-party')}
        onMap={() => setScreen('map-play')}/>;
    case 'map-edit':
      return <ScreenMapEdit
        onCancel={() => setScreen('design-list')}
        onSave={() => setScreen('mission-settings')}
        onItemTap={(k) => {
          if (k === 'quiz')  setScreen('item-detail-quiz');
          else if (k === 'runEnd') setScreen('item-detail-runEnd');
          else if (k === 'mine')   setScreen('item-detail-mine');
          else setScreen('item-detail-hint');
        }}/>;
    case 'badges':
      return <ScreenBadges onNav={(t) => {
        if (t === 'list')        setScreen('list');
        else if (t === 'design') setScreen('map-edit');
        else if (t === 'help')   setScreen('help-items');
      }}/>;
    case 'help-items':
      return <ScreenItemGlossary onBack={() => setScreen('list')}
        onTab={onHelpTab} onNav={onHelpNav}/>;
    case 'help-howto':
      return <ScreenHowToPlay onBack={() => setScreen('list')}
        onTab={onHelpTab} onNav={onHelpNav}/>;
    case 'help-design':
      return <ScreenDesignGuide onBack={() => setScreen('list')}
        onTab={onHelpTab} onNav={onHelpNav}
        onStartDesign={() => setScreen('design-list')}/>;
    case 'tutorial':
      return <ScreenTutorial step={tutStep} onStep={setTutStep}
        onDone={() => setScreen('list')}/>;
    case 'design-list':
      return <ScreenDesignList
        onBack={() => setScreen('list')}
        onNew={() => setScreen('map-edit')}
        onPick={() => setScreen('design-action')}
        onNav={(t) => {
          if (t === 'list') setScreen('list');
          else if (t === 'badge') setScreen('badges');
          else if (t === 'help') setScreen('help-items');
        }}/>;
    case 'design-action':
      return <ScreenDesignAction
        onModify={() => setScreen('map-edit')}
        onTest={() => setScreen('mission-info')}
        onUpload={() => setScreen('design-list')}
        onCancel={() => setScreen('design-list')}
        onNav={(t) => {
          if (t === 'list') setScreen('list');
          else if (t === 'badge') setScreen('badges');
          else if (t === 'help') setScreen('help-items');
        }}/>;
    case 'mission-info':
      return <ScreenMissionInfo showStartSheet={true}
        onBack={() => setScreen('design-list')}
        onPlay={() => setScreen('map-play')}
        onNav={(t) => {
          if (t === 'list') setScreen('list');
          else if (t === 'badge') setScreen('badges');
          else if (t === 'help') setScreen('help-items');
        }}/>;
    case 'mission-settings':
      return <ScreenMissionSettings
        onCancel={() => setScreen('map-edit')}
        onSave={() => setScreen('design-list')}
        onNav={(t) => {
          if (t === 'list') setScreen('list');
          else if (t === 'badge') setScreen('badges');
          else if (t === 'help') setScreen('help-items');
        }}/>;
    case 'item-detail-hint':
      return <ScreenItemDetail kind="hint"
        onDone={() => setScreen('map-edit')}
        onDelete={() => setScreen('map-edit')}/>;
    case 'item-detail-quiz':
      return <ScreenItemDetail kind="quiz"
        onDone={() => setScreen('map-edit')}
        onDelete={() => setScreen('map-edit')}/>;
    case 'item-detail-runEnd':
      return <ScreenItemDetail kind="runEnd"
        onDone={() => setScreen('map-edit')}
        onDelete={() => setScreen('map-edit')}/>;
    case 'item-detail-mine':
      return <ScreenItemDetail kind="mine"
        onDone={() => setScreen('map-edit')}
        onDelete={() => setScreen('map-edit')}/>;
    case 'map-edit-picker':
      return <ScreenMapEditPicker
        onCancel={() => setScreen('map-edit')}
        onSave={() => setScreen('mission-settings')}
        onDone={() => setScreen('map-edit')}/>;
    case 'design-list-v2':
      return <ScreenDesignListV2
        onNew={() => setScreen('map-edit')}
        onPick={() => setScreen('mission-edit-v2')}
        onNav={(t) => setScreen(navMap(t))}/>;
    case 'mission-edit-v2':
      return <ScreenMissionEditV2
        onCancel={() => setScreen('design-list-v2')}
        onSave={() => setScreen('design-list-v2')}
        onNav={(t) => setScreen(navMap(t))}/>;
    case 'item-detail-v2':
      return <ScreenItemDetailV2 kind="mine"
        onDone={() => setScreen('map-edit')}
        onCancel={() => setScreen('map-edit')}
        onDelete={() => setScreen('map-edit')}/>;
    case 'settings':
      return <ScreenSettings
        onHowToPlay={() => setScreen('help-howto')}
        onNav={(t) => setScreen(navMap(t))}/>;
    case 'my-info':
      return <ScreenMyInfo onNav={(t) => setScreen(navMap(t))}/>;
    case 'badges-v2':
      return <ScreenBadgeListV2 onNav={(t) => setScreen(navMap(t))}/>;
    case 'item-acquired':
      return (
        <div style={{ position: 'relative', width: '100%', height: '100%' }}>
          <ScreenMapPlay onCamera={() => setScreen('ar-search')} onExit={() => setScreen('list')}/>
          <ItemAcquiredPopup itemKind="start"
            title="Start Item acquired!"
            body="If you touch OK, the item will be released Mission."
            onConfirm={() => setScreen('map-play')}/>
        </div>
      );
    default:
      return <div style={{ padding: 20 }}>Unknown screen: {id}</div>;
  }
}


// Map BottomNav5 tab id → screen id
function navMap(t) {
  return ({
    list: 'list',
    design: 'design-list-v2',
    info: 'my-info',
    badge: 'badges-v2',
    settings: 'settings',
  })[t] || 'list';
}

function App() {
  const [t, setTweak] = useTweaks(TWEAK_DEFAULTS);
  const [screen, setScreenState] = React.useState(t.screen || 'list');
  const [tutStep, setTutStep] = React.useState(1);
  const [tab, setTab] = React.useState('popular');

  // Setting the prototype screen also updates the tweak so it persists
  const setScreen = React.useCallback((id) => {
    setScreenState(id);
    setTweak('screen', id);
  }, [setTweak]);

  // Sync from tweak (when user picks via panel)
  React.useEffect(() => {
    if (t.screen && t.screen !== screen) setScreenState(t.screen);
  }, [t.screen]);

  // Real theme — overrides --theme-* CSS vars consumed by .ps-btn--primary,
  // .ps-tab.active, .ps-nav .ps-nav-item.active, .ps-screen, Map Play / AR top
  // bars, and any other component that references the theme tokens.
  const themes = {
    green:  {
      '--theme-primary': '#58CC02', '--theme-primary-deep': '#43A601',
      '--theme-primary-shadow': '#5AA703', '--theme-primary-bg': '#D7FFB8',
      '--theme-primary-text': '#375B0A',
    },
    blue: {
      '--theme-primary': '#1CB0F6', '--theme-primary-deep': '#0084C2',
      '--theme-primary-shadow': '#0E7DBE', '--theme-primary-bg': '#D2EFFD',
      '--theme-primary-text': '#0084C2',
    },
    orange: {
      '--theme-primary': '#FF9600', '--theme-primary-deep': '#E08600',
      '--theme-primary-shadow': '#C77200', '--theme-primary-bg': '#FFE7CE',
      '--theme-primary-text': '#A55E00',
    },
    purple: {
      '--theme-primary': '#CE82FF', '--theme-primary-deep': '#8C39C8',
      '--theme-primary-shadow': '#7A2EB1', '--theme-primary-bg': '#EED4FF',
      '--theme-primary-text': '#5B1E84',
    },
  };
  const themeVars = themes[t.accent || 'green'];

  // Dark mode toggle (applied via [data-theme=dark] on wrapper)
  const dataTheme = t.dark ? 'dark' : 'light';

  // Font family swap — Jalnan (default chunky) vs Nunito (clean rounded)
  const fontVar = t.font === 'nunito'
    ? { '--font-display': '"Nunito", system-ui, sans-serif' }
    : {};

  // Animation speed multiplier — applied to a few keyframe anims via a var
  const speedVar = t.speed != null ? { '--ps-speed': String(t.speed) } : {};

  const wrapperStyle = { ...themeVars, ...fontVar, ...speedVar };

  return (
    <div style={wrapperStyle} data-theme={dataTheme} data-mascot={t.mascot === false ? 'off' : 'on'}>
      <DesignCanvas>
        <DCSection id="proto" title="Interactive Prototype"
          subtitle="실제 작동하는 클릭 가능 프로토타입 — 화면 안의 버튼을 눌러 이동해 보세요">
          <DCArtboard id="proto-iphone" label={`PlaySpot · ${SCREENS.find(s=>s.id===screen)?.label || screen}`}
            width={420} height={740}>
            <div style={{
              width: 420, height: 740,
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              padding: 20, boxSizing: 'border-box',
            }}>
              <PSPhone width={320} height={568}>
                <RenderScreen id={screen} setScreen={setScreen}
                  tutStep={tutStep} setTutStep={setTutStep}
                  tab={tab} setTab={setTab}/>
              </PSPhone>
            </div>
          </DCArtboard>

          <DCArtboard id="flowmap" label="Flow Map" width={380} height={740}>
            <FlowMap currentScreen={screen} setScreen={setScreen}/>
          </DCArtboard>
        </DCSection>

        <DCSection id="design-flow" title="Mission Design Flow — 디자인 흐름"
          subtitle="Design 탭에서 미션을 만들고, 아이템을 배치하고, 테스트해서 업로드하는 전체 흐름">
          {SCREENS.filter(s => s.group === 'Design').map(s => (
            <DCArtboard key={s.id} id={`board-${s.id}`} label={s.label}
              width={420} height={740}>
              <ScreenBoard id={s.id}/>
            </DCArtboard>
          ))}
        </DCSection>

        <DCSection id="help" title="Help / Tutorial — 리디자인"
          subtitle="원본의 ITEM, PlaySpot, Mission Design 페이지 → Duolingo 스타일로 재구성">
          {SCREENS.filter(s => s.group === 'Help').map(s => (
            <DCArtboard key={s.id} id={`board-${s.id}`} label={s.label}
              width={420} height={740}>
              <ScreenBoard id={s.id}/>
            </DCArtboard>
          ))}
        </DCSection>

        <DCSection id="in-game" title="In-Game Screens"
          subtitle="실제 미션 플레이 중 보이는 화면들">
          {SCREENS.filter(s => s.group === 'In-game').map(s => (
            <DCArtboard key={s.id} id={`board-${s.id}`} label={s.label}
              width={420} height={740}>
              <ScreenBoard id={s.id}/>
            </DCArtboard>
          ))}
        </DCSection>

        <DCSection id="meta" title="Meta Screens"
          subtitle="미션 목록, 편집, 뱃지, 온보딩">
          {SCREENS.filter(s => s.group === 'Meta').map(s => (
            <DCArtboard key={s.id} id={`board-${s.id}`} label={s.label}
              width={420} height={740}>
              <ScreenBoard id={s.id}/>
            </DCArtboard>
          ))}
        </DCSection>
      </DesignCanvas>

      <TweaksPanel title="Tweaks">
        <TweakSection label="Color theme">
          <TweakColor label="Accent"
            value={({ green: '#58CC02', blue: '#1CB0F6', orange: '#FF9600', purple: '#CE82FF' })[t.accent || 'green']}
            options={['#58CC02', '#1CB0F6', '#FF9600', '#CE82FF']}
            onChange={(hex) => {
              const m = { '#58cc02': 'green', '#1cb0f6': 'blue', '#ff9600': 'orange', '#ce82ff': 'purple' };
              setTweak('accent', m[String(hex).toLowerCase()] || 'green');
            }}/>
          <TweakToggle label="Dark mode" value={!!t.dark}
            onChange={(v) => setTweak('dark', v)}/>
        </TweakSection>
        <TweakSection label="Typography & character">
          <TweakRadio label="Font" value={t.font || 'jalnan'}
            options={[
              { label: '잘난체', value: 'jalnan' },
              { label: 'Nunito', value: 'nunito' },
            ]}
            onChange={(v) => setTweak('font', v)}/>
          <TweakToggle label="Mascot (여우)" value={t.mascot !== false}
            onChange={(v) => setTweak('mascot', v)}/>
        </TweakSection>
        <TweakSection label="Motion">
          <TweakSlider label="Animation speed"
            value={t.speed ?? 1} min={0} max={2} step={0.1}
            onChange={(v) => setTweak('speed', v)}/>
          <TweakToggle label="Tutorial helper bubbles" value={!!t.showHints}
            onChange={(v) => setTweak('showHints', v)}/>
        </TweakSection>
        <TweakSection label="Prototype">
          <TweakSelect label="Jump to screen"
            value={t.screen || 'list'}
            options={SCREENS.map(s => ({ label: s.label, value: s.id }))}
            onChange={(v) => { setTweak('screen', v); setScreenState(v); }}/>
          <TweakButton label="Reset to Mission List"
            onClick={() => { setTweak('screen', 'list'); setScreenState('list'); }}/>
        </TweakSection>
      </TweaksPanel>
    </div>
  );
}

// Standalone single-screen artboard (no nav handlers — pure showcase)
function ScreenBoard({ id }) {
  const [tab, setTab] = React.useState('popular');
  const [step, setStep] = React.useState(1);
  return (
    <div style={{
      width: 420, height: 740,
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      padding: 20, boxSizing: 'border-box',
    }}>
      <PSPhone width={320} height={568}>
        <RenderScreen id={id}
          setScreen={() => {}}
          tutStep={step} setTutStep={setStep}
          tab={tab} setTab={setTab}/>
      </PSPhone>
    </div>
  );
}

// FlowMap — visual diagram showing how screens connect, with click-to-jump
function FlowMap({ currentScreen, setScreen }) {
  const nodes = [
    { id: 'list',             x: 30,  y: 10,  label: 'Mission List' },
    { id: 'badges',           x: 200, y: 10,  label: 'Badges' },
    { id: 'design-list',      x: 30,  y: 90,  label: 'My Designs' },
    { id: 'design-action',    x: 200, y: 90,  label: 'Action Sheet' },
    { id: 'mission-info',     x: 30,  y: 170, label: 'Test Preview' },
    { id: 'mission-settings', x: 200, y: 170, label: 'Settings' },
    { id: 'map-edit',         x: 30,  y: 250, label: 'Map Edit' },
    { id: 'map-edit-picker',  x: 200, y: 250, label: 'Item Picker' },
    { id: 'item-detail-hint', x: 30,  y: 330, label: 'Item · Hint' },
    { id: 'item-detail-quiz', x: 200, y: 330, label: 'Item · Quiz' },
    { id: 'item-detail-runEnd', x: 30, y: 410, label: 'Item · Run End' },
    { id: 'item-detail-mine', x: 200, y: 410, label: 'Item · Mine' },
    { id: 'help-items',       x: 30,  y: 490, label: 'Help · Items' },
    { id: 'help-howto',       x: 200, y: 490, label: 'How to Play' },
    { id: 'help-design',      x: 30,  y: 560, label: 'Design Guide' },
    { id: 'map-play',         x: 200, y: 560, label: 'Map Play' },
    { id: 'ar-search',        x: 30,  y: 640, label: 'AR Search' },
    { id: 'ar-touch',         x: 200, y: 640, label: 'AR Touch' },
    { id: 'ar-party',         x: 30,  y: 720, label: 'AR Found' },
    { id: 'hint',             x: 200, y: 720, label: 'Hint Popup' },
  ];
  const edges = [
    ['list', 'design-list'], ['design-list', 'design-action'],
    ['design-action', 'mission-info'], ['mission-info', 'map-play'],
    ['design-action', 'map-edit'], ['map-edit', 'map-edit-picker'],
    ['map-edit', 'item-detail-hint'], ['map-edit', 'item-detail-quiz'],
    ['map-edit', 'item-detail-runEnd'], ['map-edit', 'item-detail-mine'],
    ['map-edit', 'mission-settings'], ['mission-settings', 'design-list'],
    ['list', 'help-items'], ['help-items', 'help-howto'],
    ['help-howto', 'help-design'],
    ['map-play', 'ar-search'], ['ar-search', 'ar-touch'],
    ['ar-touch', 'hint'], ['hint', 'ar-party'],
  ];
  const np = (id) => nodes.find(n => n.id === id);

  return (
    <div style={{
      width: 380, height: 740, padding: 16, boxSizing: 'border-box',
      background: 'var(--duo-snow)',
      display: 'flex', flexDirection: 'column', gap: 8,
    }}>
      <div>
        <div className="ps-cap" style={{ fontSize: 10, color: 'var(--duo-hare)' }}>NAVIGATION</div>
        <div className="ps-display" style={{ fontSize: 22 }}>Flow Map</div>
        <div style={{ fontSize: 12, color: 'var(--duo-wolf-2)', marginTop: 4 }}>
          노드를 눌러 프로토타입을 그 화면으로 이동시킬 수 있어요.
        </div>
      </div>
      <div style={{ flex: 1, position: 'relative', minHeight: 0 }}>
        <svg width="100%" height="100%" viewBox="0 0 340 800" style={{ position: 'absolute', inset: 0 }}>
          {edges.map(([a, b], i) => {
            const na = np(a), nb = np(b);
            if (!na || !nb) return null;
            return <path key={i}
              d={`M ${na.x + 55} ${na.y + 24} Q ${(na.x + nb.x) / 2 + 50} ${(na.y + nb.y) / 2 + 24} ${nb.x + 55} ${nb.y + 24}`}
              stroke="#bbb" strokeWidth="2" fill="none" strokeDasharray="4 4"/>;
          })}
        </svg>
        {nodes.map(n => (
          <button key={n.id} onClick={() => setScreen(n.id)}
            style={{
              position: 'absolute', left: n.x, top: n.y,
              width: 110, height: 48,
              background: n.id === currentScreen ? 'var(--duo-macaw-bg)' : '#fff',
              border: `2px solid ${n.id === currentScreen ? 'var(--duo-macaw-border)' : 'var(--duo-swan-2)'}`,
              borderRadius: 12,
              boxShadow: `0 2px 0 0 ${n.id === currentScreen ? 'var(--duo-macaw-border)' : 'var(--duo-swan-2)'}`,
              cursor: 'pointer',
              fontFamily: 'var(--font-display)',
              fontWeight: 900, fontSize: 10,
              letterSpacing: '0.04em', textTransform: 'uppercase',
              color: n.id === currentScreen ? 'var(--duo-macaw-deep)' : 'var(--duo-wolf-2)',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              padding: '0 6px', textAlign: 'center', lineHeight: 1.1,
            }}>
            {n.label}
          </button>
        ))}
      </div>
    </div>
  );
}

ReactDOM.createRoot(document.getElementById('root')).render(<App/>);
