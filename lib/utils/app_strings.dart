/// 落笔 App — UI 字符串常量
/// 所有页面标题、按钮文字、提示信息集中管理
/// 未来如需国际化，只需替换此文件
library;

class AppStrings {
  AppStrings._();

  // ── 页面标题 ──────────────────────────
  static const appTitle = '落笔';
  static const bookshelf = '我的书架';
  static const inspirations = '灵感碎片';
  static const settings = '设置';
  static const statistics = '写作统计';
  static const calendar = '写作日历';
  static const recycleBin = '回收站';
  static const characterProfile = '人物卡';
  static const outline = '大纲';

  // ── 书架 ──────────────────────────────
  static const recentReading = '最近阅读';
  static const otherWorks = '其他作品';
  static const continueWriting = '继续写作';
  static const newBook = '新建作品';
  static const bookCount = '部';

  // ── 灵感 ──────────────────────────────
  static const recordInspiration = '记录灵感';
  static const editInspiration = '编辑灵感';
  static const quickRecord = '快速记录';
  static const noInspirations = '还没有灵感碎片';
  static const noInspirationsHint = '点击右下角 + 记录第一条灵感';
  static const noInspirationsHintDesktop = '点击上方「+ 快速记录」或底部输入栏记录灵感';
  static const recordHint = '想到什么随时记下来';
  static const inputPlaceholder = '记录一个灵感...';
  static const writeInspiration = '写下灵感...';
  static const supplementaryNote = '补充说明 (可选)';
  static const linkToBook = '关联作品 (可选)';
  static const enterBookName = '输入作品名称...';
  static const searchInspirations = '搜索灵感碎片...';
  static const noMatchFound = '没有找到匹配的灵感';

  // ── 通用操作 ──────────────────────────
  static const save = '保存';
  static const cancel = '取消';
  static const delete = '删除';
  static const confirm = '确定';
  static const record = '记录';
  static const search = '搜索';
  static const clear = '清除';
  static const back = '返回';

  // ── 删除确认 ──────────────────────────
  static const confirmDelete = '确认删除';
  static const confirmDeleteHint = '确定要删除这条灵感碎片吗？';
  static const deleteForever = '彻底删除';
  static const deleteForeverHint = '此操作将永久删除该书及其所有章节，且无法撤销！';
  static const deleteForeverConfirm = '彻底粉碎';

  // ── 反馈 ──────────────────────────────
  static const restoreSuccess = '书籍已恢复到书架';
  static const restoreFailed = '恢复失败，请重试';
  static const deleteSuccess = '已彻底删除';
  static const deleteFailed = '删除失败，请重试';
  static const exportSuccess = '已成功将所有书籍打包导出至：';
  static const exportFailed = 'TXT 导出失败，请重试';
  static const chapterSaved = '章节保存成功';
  static const chapterRestored = '章节已恢复';

  // ── 设置 ──────────────────────────────
  static const dataSecurity = '数据与安全';
  static const lanSync = '局域网同步';
  static const lanSyncDesc = '扫码与附近设备同步数据';
  static const backupRestore = '备份与恢复';
  static const exportTxt = '导出 TXT';
  static const aiSettings = 'AI 设置';
  static const about = '关于';
  static const version = '版本';

  // ── 个人主页 ──────────────────────────
  static const editNickname = '修改昵称';
  static const consecutiveDays = '连续创作(天)';
  static const totalWords = '累计字数';
  static const todayWords = '今日码字';
  static const writingRecord = '写作记录';
  static const levelTitle = '等级称号';
  static const aiAssistant = 'AI 助手';
  static const appSettings = '应用设置';

  // ── 统计 ──────────────────────────────
  static const dailyStats = '每日统计';
  static const monthlyReport = '月度报告';
  static const writingStreak = '连续写作';

  // ── 标签 ──────────────────────────────
  static const tagAll = '全部';
  static const tagCharacter = '角色';
  static const tagPlot = '情节';
  static const tagScene = '场景';
  static const tagQuote = '金句';
  static const tagWorldBuilding = '世界观';
  static const tagOther = '其他';
  static const tagSelect = '标签';
}
