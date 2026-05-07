import 'package:flutter/widgets.dart';

enum AppLanguage {
  english('en', 'English', Locale('en')),
  arabicEgyptian('ar_EG', 'Arabic Egyptian', Locale('ar', 'EG'));

  const AppLanguage(this.code, this.label, this.locale);

  final String code;
  final String label;
  final Locale locale;

  bool get isRtl => this == AppLanguage.arabicEgyptian;

  static AppLanguage fromCode(String? code) {
    return AppLanguage.values.firstWhere(
      (language) => language.code == code,
      orElse: () => AppLanguage.english,
    );
  }
}

class L10nKeys {
  const L10nKeys._();

  static const dashboard = 'dashboard';
  static const members = 'members';
  static const checkIn = 'checkIn';
  static const staff = 'staff';
  static const plans = 'plans';
  static const payments = 'payments';
  static const finance = 'finance';
  static const memberApp = 'memberApp';
  static const aiEngine = 'aiEngine';
  static const settings = 'settings';
  static const platformAdmin = 'platformAdmin';
  static const save = 'save';
  static const cancel = 'cancel';
  static const close = 'close';
  static const delete = 'delete';
  static const edit = 'edit';
  static const add = 'add';
  static const search = 'search';
  static const loading = 'loading';
  static const retry = 'retry';
  static const details = 'details';
  static const active = 'active';
  static const inactive = 'inactive';
  static const suspended = 'suspended';
  static const cancelled = 'cancelled';
  static const error = 'error';
  static const success = 'success';
  static const language = 'language';
  static const english = 'english';
  static const arabicEgyptian = 'arabicEgyptian';
  static const languageChanged = 'languageChanged';
  static const settingsSubtitle = 'settingsSubtitle';
  static const dashboardSubtitle = 'dashboardSubtitle';
  static const membersSubtitle = 'membersSubtitle';
  static const paymentsTitle = 'paymentsTitle';
  static const paymentsSubtitle = 'paymentsSubtitle';
  static const checkInTitle = 'checkInTitle';
  static const checkInSubtitle = 'checkInSubtitle';
  static const financeTitle = 'financeTitle';
  static const financeSubtitle = 'financeSubtitle';
  static const memberAppTitle = 'memberAppTitle';
  static const memberAppSubtitle = 'memberAppSubtitle';
  static const platformAdminSubtitle = 'platformAdminSubtitle';
  static const saveProfile = 'saveProfile';
  static const saveOccupancy = 'saveOccupancy';
  static const saveBusinessSettings = 'saveBusinessSettings';
  static const saving = 'saving';
  static const searchMembers = 'searchMembers';
  static const addMember = 'addMember';
  static const paymentsAndRenewals = 'paymentsAndRenewals';
  static const workspace = 'workspace';
  static const system = 'system';
  static const keyMetrics = 'keyMetrics';
  static const operations = 'operations';
  static const totalMembers = 'totalMembers';
  static const activeMembers = 'activeMembers';
  static const activeSubscriptions = 'activeSubscriptions';
  static const expiredSubscriptions = 'expiredSubscriptions';
  static const expiringSoon = 'expiringSoon';
  static const todayCheckins = 'todayCheckins';
  static const todayRevenue = 'todayRevenue';
  static const monthRevenue = 'monthRevenue';
  static const currentOccupancy = 'currentOccupancy';
  static const liveOccupancy = 'liveOccupancy';
  static const recentPayments = 'recentPayments';
  static const recentCheckins = 'recentCheckins';
  static const activeSessions = 'activeSessions';
  static const noRecordsFound = 'noRecordsFound';
  static const noGymDataYet = 'noGymDataYet';
  static const count = 'count';
  static const capacity = 'capacity';
  static const usage = 'usage';
  static const viewDetails = 'viewDetails';
  static const allMembers = 'allMembers';
  static const memberStatus = 'memberStatus';
  static const subscriptionStatus = 'subscriptionStatus';
  static const accessStatus = 'accessStatus';
  static const overview = 'overview';
  static const subscription = 'subscription';
  static const attendance = 'attendance';
  static const access = 'access';
  static const contact = 'contact';
  static const currentPlan = 'currentPlan';
  static const paymentStatus = 'paymentStatus';
  static const accessCredentials = 'accessCredentials';
  static const editMember = 'editMember';
  static const recordPaymentRenew = 'recordPaymentRenew';
  static const selectMember = 'selectMember';
  static const selectPlan = 'selectPlan';
  static const paymentDetails = 'paymentDetails';
  static const amountPaid = 'amountPaid';
  static const paymentMethod = 'paymentMethod';
  static const receiptSummary = 'receiptSummary';
  static const receiptDetails = 'receiptDetails';
  static const recentReceipts = 'recentReceipts';
  static const noReceiptsYet = 'noReceiptsYet';
  static const createPayment = 'createPayment';
  static const copyReceiptNumber = 'copyReceiptNumber';
  static const viewMember = 'viewMember';
  static const subscriptionPlan = 'subscriptionPlan';
  static const systemDetails = 'systemDetails';
  static const notes = 'notes';
  static const scanAccessCode = 'scanAccessCode';
  static const checkOut = 'checkOut';
  static const empty = 'empty';
  static const low = 'low';
  static const moderate = 'moderate';
  static const busy = 'busy';
  static const full = 'full';
  static const currentlyInside = 'currentlyInside';
  static const noActiveSessions = 'noActiveSessions';
  static const totalRevenue = 'totalRevenue';
  static const totalExpenses = 'totalExpenses';
  static const staffPayroll = 'staffPayroll';
  static const productSales = 'productSales';
  static const netProfit = 'netProfit';
  static const revenue = 'revenue';
  static const expenses = 'expenses';
  static const payroll = 'payroll';
  static const products = 'products';
  static const audit = 'audit';
  static const quickActions = 'quickActions';
  static const addExpense = 'addExpense';
  static const addStaffPayroll = 'addStaffPayroll';
  static const addProduct = 'addProduct';
  static const recordProductSale = 'recordProductSale';
  static const cancelExpense = 'cancelExpense';
  static const cancelPayroll = 'cancelPayroll';
  static const cancelProductSale = 'cancelProductSale';
  static const calculationFormula = 'calculationFormula';
  static const gymProfile = 'gymProfile';
  static const name = 'name';
  static const slug = 'slug';
  static const country = 'country';
  static const currency = 'currency';
  static const timezone = 'timezone';
  static const status = 'status';
  static const phone = 'phone';
  static const email = 'email';
  static const address = 'address';
  static const occupancySettings = 'occupancySettings';
  static const businessSettings = 'businessSettings';
  static const paymentMethods = 'paymentMethods';
  static const suspendGym = 'suspendGym';
  static const resumeGym = 'resumeGym';
  static const markCancelled = 'markCancelled';
  static const suspensionReason = 'suspensionReason';
  static const cancellationReason = 'cancellationReason';
  static const tenantStatus = 'tenantStatus';
  static const reasonRequired = 'reasonRequired';
  static const noGymsFound = 'noGymsFound';
  static const home = 'home';
  static const digitalMembershipCard = 'digitalMembershipCard';
  static const accessAllowed = 'accessAllowed';
  static const accessBlocked = 'accessBlocked';
  static const noPaymentsYet = 'noPaymentsYet';
  static const noAccessCredential = 'noAccessCredential';
  static const notCurrentlyCheckedIn = 'notCurrentlyCheckedIn';
  static const unknown = 'unknown';
  static const notAvailable = 'notAvailable';
  static const notSet = 'notSet';
  static const none = 'none';
  static const amount = 'amount';
  static const date = 'date';
  static const method = 'method';
  static const today = 'today';
  static const thisMonth = 'thisMonth';
  static const currentMonth = 'currentMonth';
  static const previousMonth = 'previousMonth';
  static const nextMonth = 'nextMonth';
  static const recentActivity = 'recentActivity';
  static const selectedMember = 'selectedMember';
  static const selectedPlan = 'selectedPlan';
  static const receiptNumber = 'receiptNumber';
  static const copied = 'copied';
  static const paid = 'paid';
  static const partial = 'partial';
  static const unpaid = 'unpaid';
  static const cash = 'cash';
  static const card = 'card';
  static const online = 'online';
  static const wallet = 'wallet';
  static const bankTransfer = 'bankTransfer';
  static const subscriptionStart = 'subscriptionStart';
  static const subscriptionEnd = 'subscriptionEnd';
  static const paidAmount = 'paidAmount';
  static const remainingAmount = 'remainingAmount';
  static const scannerReady = 'scannerReady';
  static const checkedInSuccessfully = 'checkedInSuccessfully';
  static const checkedOutSuccessfully = 'checkedOutSuccessfully';
  static const activeSession = 'activeSession';
  static const checkInTime = 'checkInTime';
  static const checkOutTime = 'checkOutTime';
  static const memberPhone = 'memberPhone';
  static const manualAdjustment = 'manualAdjustment';
  static const increase = 'increase';
  static const decrease = 'decrease';
  static const currentCount = 'currentCount';
  static const percentage = 'percentage';
  static const noRecentCheckins = 'noRecentCheckins';
  static const profile = 'profile';
  static const contactDetails = 'contactDetails';
  static const memberInformation = 'memberInformation';
  static const subscriptionDetails = 'subscriptionDetails';
  static const paymentHistory = 'paymentHistory';
  static const attendanceSessions = 'attendanceSessions';
  static const legacyCheckinLogs = 'legacyCheckinLogs';
  static const currentStatus = 'currentStatus';
  static const noPaymentsFound = 'noPaymentsFound';
  static const noAttendanceSessionsFound = 'noAttendanceSessionsFound';
  static const stillInside = 'stillInside';
  static const lastCheckout = 'lastCheckout';
  static const checkInMethod = 'checkInMethod';
  static const checkOutMethod = 'checkOutMethod';
  static const duration = 'duration';
  static const createdAt = 'createdAt';
  static const updatedAt = 'updatedAt';
  static const assignedAt = 'assignedAt';
  static const notAssigned = 'notAssigned';
  static const allowed = 'allowed';
  static const blocked = 'blocked';
  static const warning = 'warning';
  static const disabled = 'disabled';
  static const lost = 'lost';
  static const replaced = 'replaced';
  static const title = 'title';
  static const category = 'category';
  static const quantity = 'quantity';
  static const unitPrice = 'unitPrice';
  static const costPrice = 'costPrice';
  static const salePrice = 'salePrice';
  static const stock = 'stock';
  static const productCost = 'productCost';
  static const operatingExpenses = 'operatingExpenses';
  static const membershipRevenue = 'membershipRevenue';
  static const grossRevenue = 'grossRevenue';
  static const executiveSummary = 'executiveSummary';
  static const financialOverview = 'financialOverview';
  static const monthReport = 'monthReport';
  static const expenseDetails = 'expenseDetails';
  static const payrollDetails = 'payrollDetails';
  static const productDetails = 'productDetails';
  static const saleDetails = 'saleDetails';
  static const cancelRecord = 'cancelRecord';
  static const myMembership = 'myMembership';
  static const subscriptionEnds = 'subscriptionEnds';
  static const showQrAtReception = 'showQrAtReception';
  static const accessWarning = 'accessWarning';
  static const peopleInsideNow = 'peopleInsideNow';
  static const noAttendanceYet = 'noAttendanceYet';
  static const memberProfileIncomplete = 'memberProfileIncomplete';
  static const memberProfileNotLinked = 'memberProfileNotLinked';
  static const memberProfileNotFound = 'memberProfileNotFound';
  static const tenantControl = 'tenantControl';
  static const actionAffectsGymAccess = 'actionAffectsGymAccess';
  static const gymSuspendedSuccess = 'gymSuspendedSuccess';
  static const gymResumedSuccess = 'gymResumedSuccess';
  static const gymCancelledSuccess = 'gymCancelledSuccess';
  static const archiveMember = 'archiveMember';
  static const deactivateMember = 'deactivateMember';
  static const memberArchivedSuccess = 'memberArchivedSuccess';
  static const memberArchivedMessage = 'memberArchivedMessage';
  static const archivedCheckinBlocked = 'archivedCheckinBlocked';
  static const archivePreservesHistory = 'archivePreservesHistory';
}

class AppLocalizations {
  const AppLocalizations(this.language);

  final AppLanguage language;

  static AppLocalizations of(BuildContext context) {
    return AppLocalizations.forLocale(Localizations.localeOf(context));
  }

  static AppLocalizations forLocale(Locale locale) {
    final code = locale.countryCode == null
        ? locale.languageCode
        : '${locale.languageCode}_${locale.countryCode}';
    return AppLocalizations(AppLanguage.fromCode(code));
  }

  String t(String key) {
    return _localizedValues[language]?[key] ??
        _localizedValues[AppLanguage.english]?[key] ??
        key;
  }
}

extension AppLocalizationsX on BuildContext {
  String t(String key) => AppLocalizations.of(this).t(key);
}

const _localizedValues = <AppLanguage, Map<String, String>>{
  AppLanguage.english: {
    L10nKeys.dashboard: 'Dashboard',
    L10nKeys.members: 'Members',
    L10nKeys.checkIn: 'Check-in',
    L10nKeys.staff: 'Staff',
    L10nKeys.plans: 'Plans',
    L10nKeys.payments: 'Payments',
    L10nKeys.finance: 'Finance',
    L10nKeys.memberApp: 'Member App',
    L10nKeys.aiEngine: 'AI Engine',
    L10nKeys.settings: 'Settings',
    L10nKeys.platformAdmin: 'Platform Admin',
    L10nKeys.save: 'Save',
    L10nKeys.cancel: 'Cancel',
    L10nKeys.close: 'Close',
    L10nKeys.delete: 'Delete',
    L10nKeys.edit: 'Edit',
    L10nKeys.add: 'Add',
    L10nKeys.search: 'Search',
    L10nKeys.loading: 'Loading',
    L10nKeys.retry: 'Retry',
    L10nKeys.details: 'Details',
    L10nKeys.active: 'Active',
    L10nKeys.inactive: 'Inactive',
    L10nKeys.suspended: 'Suspended',
    L10nKeys.cancelled: 'Cancelled',
    L10nKeys.error: 'Error',
    L10nKeys.success: 'Success',
    L10nKeys.language: 'Language',
    L10nKeys.english: 'English',
    L10nKeys.arabicEgyptian: 'Arabic Egyptian',
    L10nKeys.languageChanged: 'Language updated.',
    L10nKeys.settingsSubtitle: 'Manage production gym configuration.',
    L10nKeys.dashboardSubtitle:
        'Tap any card for records and operational detail.',
    L10nKeys.membersSubtitle:
        'Manage gym members, access, plans, and member records.',
    L10nKeys.paymentsTitle: 'Payments & Renewals',
    L10nKeys.paymentsSubtitle:
        'Record membership payments, renew subscriptions, and review recent gym receipts.',
    L10nKeys.checkInTitle: 'Check-in & Attendance',
    L10nKeys.checkInSubtitle:
        'Scan or enter member access code, then manage active sessions.',
    L10nKeys.financeTitle: 'Finance & Operations',
    L10nKeys.financeSubtitle:
        'Track revenue, costs, products, and operational cash flow.',
    L10nKeys.memberAppTitle: 'Member App',
    L10nKeys.memberAppSubtitle:
        'Member self-service view for subscriptions, attendance, and receipts.',
    L10nKeys.platformAdminSubtitle:
        'Manage tenant access for gyms on the platform.',
    L10nKeys.saveProfile: 'Save Profile',
    L10nKeys.saveOccupancy: 'Save Occupancy',
    L10nKeys.saveBusinessSettings: 'Save Business Settings',
    L10nKeys.saving: 'Saving',
    L10nKeys.searchMembers: 'Search members...',
    L10nKeys.addMember: 'Add Member',
    L10nKeys.paymentsAndRenewals: 'Payments & Renewals',
    L10nKeys.workspace: 'Workspace',
    L10nKeys.system: 'System',
    L10nKeys.keyMetrics: 'Key Metrics',
    L10nKeys.operations: 'Operations',
    L10nKeys.totalMembers: 'Total Members',
    L10nKeys.activeMembers: 'Active Members',
    L10nKeys.activeSubscriptions: 'Active Subscriptions',
    L10nKeys.expiredSubscriptions: 'Expired Subscriptions',
    L10nKeys.expiringSoon: 'Expiring Soon',
    L10nKeys.todayCheckins: 'Today Check-ins',
    L10nKeys.todayRevenue: 'Today Revenue',
    L10nKeys.monthRevenue: 'Month Revenue',
    L10nKeys.currentOccupancy: 'Current Occupancy',
    L10nKeys.liveOccupancy: 'Live Occupancy',
    L10nKeys.recentPayments: 'Recent Payments',
    L10nKeys.recentCheckins: 'Recent Check-ins',
    L10nKeys.activeSessions: 'Active Sessions',
    L10nKeys.noRecordsFound: 'No records found.',
    L10nKeys.noGymDataYet: 'No Gym Data Yet',
    L10nKeys.count: 'Count',
    L10nKeys.capacity: 'Capacity',
    L10nKeys.usage: 'Usage',
    L10nKeys.viewDetails: 'View details',
    L10nKeys.allMembers: 'All Members',
    L10nKeys.memberStatus: 'Member Status',
    L10nKeys.subscriptionStatus: 'Subscription Status',
    L10nKeys.accessStatus: 'Access Status',
    L10nKeys.overview: 'Overview',
    L10nKeys.subscription: 'Subscription',
    L10nKeys.attendance: 'Attendance',
    L10nKeys.access: 'Access',
    L10nKeys.contact: 'Contact',
    L10nKeys.currentPlan: 'Current Plan',
    L10nKeys.paymentStatus: 'Payment Status',
    L10nKeys.accessCredentials: 'Access Credentials',
    L10nKeys.editMember: 'Edit Member',
    L10nKeys.recordPaymentRenew: 'Record Payment / Renew',
    L10nKeys.selectMember: 'Select Member',
    L10nKeys.selectPlan: 'Select Plan',
    L10nKeys.paymentDetails: 'Payment Details',
    L10nKeys.amountPaid: 'Amount Paid',
    L10nKeys.paymentMethod: 'Payment Method',
    L10nKeys.receiptSummary: 'Receipt Summary',
    L10nKeys.receiptDetails: 'Receipt Details',
    L10nKeys.recentReceipts: 'Recent Receipts',
    L10nKeys.noReceiptsYet: 'No receipts yet.',
    L10nKeys.createPayment: 'Create Payment',
    L10nKeys.copyReceiptNumber: 'Copy Receipt Number',
    L10nKeys.viewMember: 'View Member',
    L10nKeys.subscriptionPlan: 'Subscription / Plan',
    L10nKeys.systemDetails: 'System Details',
    L10nKeys.notes: 'Notes',
    L10nKeys.scanAccessCode: 'Scan NFC / QR / Access Code',
    L10nKeys.checkOut: 'Check Out',
    L10nKeys.empty: 'Empty',
    L10nKeys.low: 'Low',
    L10nKeys.moderate: 'Moderate',
    L10nKeys.busy: 'Busy',
    L10nKeys.full: 'Full',
    L10nKeys.currentlyInside: 'Currently inside',
    L10nKeys.noActiveSessions: 'No active sessions.',
    L10nKeys.totalRevenue: 'Total Revenue',
    L10nKeys.totalExpenses: 'Total Expenses',
    L10nKeys.staffPayroll: 'Staff Payroll',
    L10nKeys.productSales: 'Product Sales',
    L10nKeys.netProfit: 'Net Profit',
    L10nKeys.revenue: 'Revenue',
    L10nKeys.expenses: 'Expenses',
    L10nKeys.payroll: 'Payroll',
    L10nKeys.products: 'Products',
    L10nKeys.audit: 'Audit',
    L10nKeys.quickActions: 'Quick Actions',
    L10nKeys.addExpense: 'Add Expense',
    L10nKeys.addStaffPayroll: 'Add Staff Payroll',
    L10nKeys.addProduct: 'Add Product',
    L10nKeys.recordProductSale: 'Record Product Sale',
    L10nKeys.cancelExpense: 'Cancel Expense',
    L10nKeys.cancelPayroll: 'Cancel Payroll',
    L10nKeys.cancelProductSale: 'Cancel Product Sale',
    L10nKeys.calculationFormula: 'Calculation Formula',
    L10nKeys.gymProfile: 'Gym Profile',
    L10nKeys.name: 'Name',
    L10nKeys.slug: 'Slug',
    L10nKeys.country: 'Country',
    L10nKeys.currency: 'Currency',
    L10nKeys.timezone: 'Timezone',
    L10nKeys.status: 'Status',
    L10nKeys.phone: 'Phone',
    L10nKeys.email: 'Email',
    L10nKeys.address: 'Address',
    L10nKeys.occupancySettings: 'Occupancy Settings',
    L10nKeys.businessSettings: 'Business Settings',
    L10nKeys.paymentMethods: 'Payment Methods',
    L10nKeys.suspendGym: 'Suspend Gym',
    L10nKeys.resumeGym: 'Resume Gym',
    L10nKeys.markCancelled: 'Mark as Cancelled',
    L10nKeys.suspensionReason: 'Suspension Reason',
    L10nKeys.cancellationReason: 'Cancellation Reason',
    L10nKeys.tenantStatus: 'Tenant Status',
    L10nKeys.reasonRequired: 'Reason is required.',
    L10nKeys.noGymsFound: 'No gyms were found.',
    L10nKeys.home: 'Home',
    L10nKeys.digitalMembershipCard: 'Digital Membership Card',
    L10nKeys.accessAllowed: 'Access Allowed',
    L10nKeys.accessBlocked: 'Access Blocked',
    L10nKeys.noPaymentsYet: 'No payments yet.',
    L10nKeys.noAccessCredential:
        'No access credential assigned yet. Please contact the gym.',
    L10nKeys.notCurrentlyCheckedIn: 'Not currently checked in.',
    L10nKeys.unknown: 'Unknown',
    L10nKeys.notAvailable: 'Not available',
    L10nKeys.notSet: 'Not set',
    L10nKeys.none: 'None',
    L10nKeys.amount: 'Amount',
    L10nKeys.date: 'Date',
    L10nKeys.method: 'Method',
    L10nKeys.today: 'Today',
    L10nKeys.thisMonth: 'This month',
    L10nKeys.currentMonth: 'Current Month',
    L10nKeys.previousMonth: 'Previous Month',
    L10nKeys.nextMonth: 'Next Month',
    L10nKeys.recentActivity: 'Recent Activity',
    L10nKeys.selectedMember: 'Selected Member',
    L10nKeys.selectedPlan: 'Selected Plan',
    L10nKeys.receiptNumber: 'Receipt Number',
    L10nKeys.copied: 'Copied',
    L10nKeys.paid: 'Paid',
    L10nKeys.partial: 'Partial',
    L10nKeys.unpaid: 'Unpaid',
    L10nKeys.cash: 'Cash',
    L10nKeys.card: 'Card',
    L10nKeys.online: 'Online',
    L10nKeys.wallet: 'Wallet',
    L10nKeys.bankTransfer: 'Bank Transfer',
    L10nKeys.subscriptionStart: 'Subscription Start',
    L10nKeys.subscriptionEnd: 'Subscription End',
    L10nKeys.paidAmount: 'Paid Amount',
    L10nKeys.remainingAmount: 'Remaining Amount',
    L10nKeys.scannerReady: 'Scanner ready',
    L10nKeys.checkedInSuccessfully: 'Checked in successfully',
    L10nKeys.checkedOutSuccessfully: 'Checked out successfully',
    L10nKeys.activeSession: 'Active Session',
    L10nKeys.checkInTime: 'Check-in Time',
    L10nKeys.checkOutTime: 'Check-out Time',
    L10nKeys.memberPhone: 'Member Phone',
    L10nKeys.manualAdjustment: 'Manual Adjustment',
    L10nKeys.increase: 'Increase',
    L10nKeys.decrease: 'Decrease',
    L10nKeys.currentCount: 'Current Count',
    L10nKeys.percentage: 'Percentage',
    L10nKeys.noRecentCheckins: 'No recent check-ins.',
    L10nKeys.profile: 'Profile',
    L10nKeys.contactDetails: 'Contact Details',
    L10nKeys.memberInformation: 'Member Information',
    L10nKeys.subscriptionDetails: 'Subscription Details',
    L10nKeys.paymentHistory: 'Payment History',
    L10nKeys.attendanceSessions: 'Attendance Sessions',
    L10nKeys.legacyCheckinLogs: 'Legacy Check-in Logs',
    L10nKeys.currentStatus: 'Current Status',
    L10nKeys.noPaymentsFound: 'No payments found.',
    L10nKeys.noAttendanceSessionsFound: 'No attendance sessions found.',
    L10nKeys.stillInside: 'Still inside',
    L10nKeys.lastCheckout: 'Last checkout',
    L10nKeys.checkInMethod: 'Check-in method',
    L10nKeys.checkOutMethod: 'Check-out method',
    L10nKeys.duration: 'Duration',
    L10nKeys.createdAt: 'Created at',
    L10nKeys.updatedAt: 'Updated at',
    L10nKeys.assignedAt: 'Assigned at',
    L10nKeys.notAssigned: 'Not assigned',
    L10nKeys.allowed: 'Allowed',
    L10nKeys.blocked: 'Blocked',
    L10nKeys.warning: 'Warning',
    L10nKeys.disabled: 'Disabled',
    L10nKeys.lost: 'Lost',
    L10nKeys.replaced: 'Replaced',
    L10nKeys.title: 'Title',
    L10nKeys.category: 'Category',
    L10nKeys.quantity: 'Quantity',
    L10nKeys.unitPrice: 'Unit Price',
    L10nKeys.costPrice: 'Cost Price',
    L10nKeys.salePrice: 'Sale Price',
    L10nKeys.stock: 'Stock',
    L10nKeys.productCost: 'Product Cost',
    L10nKeys.operatingExpenses: 'Operating Expenses',
    L10nKeys.membershipRevenue: 'Membership Revenue',
    L10nKeys.grossRevenue: 'Gross Revenue',
    L10nKeys.executiveSummary: 'Executive Summary',
    L10nKeys.financialOverview: 'Financial Overview',
    L10nKeys.monthReport: 'Month Report',
    L10nKeys.expenseDetails: 'Expense Details',
    L10nKeys.payrollDetails: 'Payroll Details',
    L10nKeys.productDetails: 'Product Details',
    L10nKeys.saleDetails: 'Sale Details',
    L10nKeys.cancelRecord: 'Cancel Record',
    L10nKeys.myMembership: 'My Membership',
    L10nKeys.subscriptionEnds: 'Subscription Ends',
    L10nKeys.showQrAtReception: 'Show this QR at reception',
    L10nKeys.accessWarning: 'Access Warning',
    L10nKeys.peopleInsideNow: 'People inside now',
    L10nKeys.noAttendanceYet: 'No attendance yet.',
    L10nKeys.memberProfileIncomplete:
        'Your gym profile is incomplete. Please contact the gym.',
    L10nKeys.memberProfileNotLinked:
        'Your member profile is not linked yet. Please contact the gym.',
    L10nKeys.memberProfileNotFound:
        'Member profile not found. Please contact the gym.',
    L10nKeys.tenantControl: 'Tenant Control',
    L10nKeys.actionAffectsGymAccess: 'This action affects gym access.',
    L10nKeys.gymSuspendedSuccess: 'Gym suspended successfully.',
    L10nKeys.gymResumedSuccess: 'Gym resumed successfully.',
    L10nKeys.gymCancelledSuccess: 'Gym cancelled successfully.',
    L10nKeys.archiveMember: 'Archive Member',
    L10nKeys.deactivateMember: 'Deactivate Member',
    L10nKeys.memberArchivedSuccess: 'Member archived successfully.',
    L10nKeys.memberArchivedMessage: 'This member has been archived.',
    L10nKeys.archivedCheckinBlocked:
        'You cannot check in because this member account is archived.',
    L10nKeys.archivePreservesHistory:
        'This will not delete payments, attendance, or history.',
  },
  AppLanguage.arabicEgyptian: {
    L10nKeys.dashboard: 'لوحة التحكم',
    L10nKeys.members: 'الأعضاء',
    L10nKeys.checkIn: 'تسجيل الدخول',
    L10nKeys.staff: 'الموظفين',
    L10nKeys.plans: 'الباقات',
    L10nKeys.payments: 'المدفوعات',
    L10nKeys.finance: 'الحسابات',
    L10nKeys.memberApp: 'تطبيق العضو',
    L10nKeys.aiEngine: 'محرك الذكاء',
    L10nKeys.settings: 'الإعدادات',
    L10nKeys.platformAdmin: 'إدارة المنصة',
    L10nKeys.save: 'حفظ',
    L10nKeys.cancel: 'إلغاء',
    L10nKeys.close: 'إغلاق',
    L10nKeys.delete: 'حذف',
    L10nKeys.edit: 'تعديل',
    L10nKeys.add: 'إضافة',
    L10nKeys.search: 'بحث',
    L10nKeys.loading: 'جاري التحميل',
    L10nKeys.retry: 'حاول تاني',
    L10nKeys.details: 'التفاصيل',
    L10nKeys.active: 'نشط',
    L10nKeys.inactive: 'غير نشط',
    L10nKeys.suspended: 'موقوف مؤقتًا',
    L10nKeys.cancelled: 'ملغي',
    L10nKeys.error: 'خطأ',
    L10nKeys.success: 'تم بنجاح',
    L10nKeys.language: 'اللغة',
    L10nKeys.english: 'إنجليزي',
    L10nKeys.arabicEgyptian: 'عربي مصري',
    L10nKeys.languageChanged: 'تم تغيير اللغة.',
    L10nKeys.settingsSubtitle: 'إدارة إعدادات الجيم الأساسية.',
    L10nKeys.dashboardSubtitle:
        'اضغط على أي كارت عشان تشوف التفاصيل والتشغيل.',
    L10nKeys.membersSubtitle:
        'إدارة الأعضاء، الدخول، الباقات، وبيانات العضو.',
    L10nKeys.paymentsTitle: 'المدفوعات والتجديدات',
    L10nKeys.paymentsSubtitle:
        'سجل المدفوعات، جدد الاشتراكات، وراجع آخر الإيصالات.',
    L10nKeys.checkInTitle: 'تسجيل الدخول والحضور',
    L10nKeys.checkInSubtitle:
        'امسح أو اكتب كود دخول العضو وبعدها تابع الجلسات النشطة.',
    L10nKeys.financeTitle: 'الحسابات والتشغيل',
    L10nKeys.financeSubtitle:
        'تابع الإيرادات، المصروفات، المنتجات، وحركة التشغيل.',
    L10nKeys.memberAppTitle: 'تطبيق العضو',
    L10nKeys.memberAppSubtitle:
        'واجهة العضو للاشتراكات، الحضور، والإيصالات.',
    L10nKeys.platformAdminSubtitle:
        'تحكم في وصول الجيمات على المنصة.',
    L10nKeys.saveProfile: 'حفظ بيانات الجيم',
    L10nKeys.saveOccupancy: 'حفظ السعة',
    L10nKeys.saveBusinessSettings: 'حفظ إعدادات التشغيل',
    L10nKeys.saving: 'جاري الحفظ',
    L10nKeys.searchMembers: 'بحث في الأعضاء...',
    L10nKeys.addMember: 'إضافة عضو',
    L10nKeys.paymentsAndRenewals: 'المدفوعات والتجديدات',
    L10nKeys.workspace: 'مساحة العمل',
    L10nKeys.system: 'النظام',
    L10nKeys.keyMetrics: 'المؤشرات الأساسية',
    L10nKeys.operations: 'التشغيل',
    L10nKeys.totalMembers: 'إجمالي الأعضاء',
    L10nKeys.activeMembers: 'الأعضاء النشطين',
    L10nKeys.activeSubscriptions: 'الاشتراكات النشطة',
    L10nKeys.expiredSubscriptions: 'اشتراكات منتهية',
    L10nKeys.expiringSoon: 'هتنتهي قريب',
    L10nKeys.todayCheckins: 'حضور النهارده',
    L10nKeys.todayRevenue: 'إيراد النهارده',
    L10nKeys.monthRevenue: 'إيراد الشهر',
    L10nKeys.currentOccupancy: 'الإشغال الحالي',
    L10nKeys.liveOccupancy: 'الإشغال المباشر',
    L10nKeys.recentPayments: 'آخر المدفوعات',
    L10nKeys.recentCheckins: 'آخر تسجيلات الدخول',
    L10nKeys.activeSessions: 'الجلسات النشطة',
    L10nKeys.noRecordsFound: 'مفيش سجلات.',
    L10nKeys.noGymDataYet: 'مفيش بيانات للجيم لسه',
    L10nKeys.count: 'العدد',
    L10nKeys.capacity: 'السعة',
    L10nKeys.usage: 'الاستخدام',
    L10nKeys.viewDetails: 'عرض التفاصيل',
    L10nKeys.allMembers: 'كل الأعضاء',
    L10nKeys.memberStatus: 'حالة العضو',
    L10nKeys.subscriptionStatus: 'حالة الاشتراك',
    L10nKeys.accessStatus: 'حالة الدخول',
    L10nKeys.overview: 'نظرة عامة',
    L10nKeys.subscription: 'الاشتراك',
    L10nKeys.attendance: 'الحضور',
    L10nKeys.access: 'الدخول',
    L10nKeys.contact: 'التواصل',
    L10nKeys.currentPlan: 'الباقة الحالية',
    L10nKeys.paymentStatus: 'حالة الدفع',
    L10nKeys.accessCredentials: 'بيانات الدخول',
    L10nKeys.editMember: 'تعديل العضو',
    L10nKeys.recordPaymentRenew: 'تسجيل دفع / تجديد',
    L10nKeys.selectMember: 'اختار عضو',
    L10nKeys.selectPlan: 'اختار باقة',
    L10nKeys.paymentDetails: 'تفاصيل الدفع',
    L10nKeys.amountPaid: 'المبلغ المدفوع',
    L10nKeys.paymentMethod: 'طريقة الدفع',
    L10nKeys.receiptSummary: 'ملخص الإيصال',
    L10nKeys.receiptDetails: 'تفاصيل الإيصال',
    L10nKeys.recentReceipts: 'آخر الإيصالات',
    L10nKeys.noReceiptsYet: 'مفيش إيصالات لسه.',
    L10nKeys.createPayment: 'إنشاء دفع',
    L10nKeys.copyReceiptNumber: 'نسخ رقم الإيصال',
    L10nKeys.viewMember: 'عرض العضو',
    L10nKeys.subscriptionPlan: 'الاشتراك / الباقة',
    L10nKeys.systemDetails: 'تفاصيل النظام',
    L10nKeys.notes: 'ملاحظات',
    L10nKeys.scanAccessCode: 'امسح NFC / QR / كود الدخول',
    L10nKeys.checkOut: 'تسجيل خروج',
    L10nKeys.empty: 'فاضي',
    L10nKeys.low: 'هادي',
    L10nKeys.moderate: 'متوسط',
    L10nKeys.busy: 'زحمة',
    L10nKeys.full: 'ممتلئ',
    L10nKeys.currentlyInside: 'موجود دلوقتي',
    L10nKeys.noActiveSessions: 'مفيش جلسات نشطة.',
    L10nKeys.totalRevenue: 'إجمالي الإيرادات',
    L10nKeys.totalExpenses: 'إجمالي المصروفات',
    L10nKeys.staffPayroll: 'مرتبات الموظفين',
    L10nKeys.productSales: 'مبيعات المنتجات',
    L10nKeys.netProfit: 'صافي الربح',
    L10nKeys.revenue: 'الإيرادات',
    L10nKeys.expenses: 'المصروفات',
    L10nKeys.payroll: 'المرتبات',
    L10nKeys.products: 'المنتجات',
    L10nKeys.audit: 'المراجعة',
    L10nKeys.quickActions: 'إجراءات سريعة',
    L10nKeys.addExpense: 'إضافة مصروف',
    L10nKeys.addStaffPayroll: 'إضافة مرتب',
    L10nKeys.addProduct: 'إضافة منتج',
    L10nKeys.recordProductSale: 'تسجيل بيع منتج',
    L10nKeys.cancelExpense: 'إلغاء مصروف',
    L10nKeys.cancelPayroll: 'إلغاء مرتب',
    L10nKeys.cancelProductSale: 'إلغاء بيع منتج',
    L10nKeys.calculationFormula: 'معادلة الحساب',
    L10nKeys.gymProfile: 'بيانات الجيم',
    L10nKeys.name: 'الاسم',
    L10nKeys.slug: 'الرابط',
    L10nKeys.country: 'البلد',
    L10nKeys.currency: 'العملة',
    L10nKeys.timezone: 'التوقيت',
    L10nKeys.status: 'الحالة',
    L10nKeys.phone: 'الموبايل',
    L10nKeys.email: 'الإيميل',
    L10nKeys.address: 'العنوان',
    L10nKeys.occupancySettings: 'إعدادات السعة',
    L10nKeys.businessSettings: 'إعدادات التشغيل',
    L10nKeys.paymentMethods: 'طرق الدفع',
    L10nKeys.suspendGym: 'إيقاف الجيم',
    L10nKeys.resumeGym: 'تشغيل الجيم',
    L10nKeys.markCancelled: 'تعليم كملغي',
    L10nKeys.suspensionReason: 'سبب الإيقاف',
    L10nKeys.cancellationReason: 'سبب الإلغاء',
    L10nKeys.tenantStatus: 'حالة الجيم',
    L10nKeys.reasonRequired: 'السبب مطلوب.',
    L10nKeys.noGymsFound: 'مفيش جيمات.',
    L10nKeys.home: 'الرئيسية',
    L10nKeys.digitalMembershipCard: 'كارت العضوية الرقمي',
    L10nKeys.accessAllowed: 'الدخول مسموح',
    L10nKeys.accessBlocked: 'الدخول ممنوع',
    L10nKeys.noPaymentsYet: 'مفيش مدفوعات لسه.',
    L10nKeys.noAccessCredential:
        'مفيش بيانات دخول متسجلة. كلم الجيم.',
    L10nKeys.notCurrentlyCheckedIn: 'مش مسجل دخول دلوقتي.',
    L10nKeys.unknown: 'غير معروف',
    L10nKeys.notAvailable: 'غير متاح',
    L10nKeys.notSet: 'مش متحدد',
    L10nKeys.none: 'لا يوجد',
    L10nKeys.amount: 'المبلغ',
    L10nKeys.date: 'التاريخ',
    L10nKeys.method: 'الطريقة',
    L10nKeys.today: 'النهارده',
    L10nKeys.thisMonth: 'الشهر ده',
    L10nKeys.currentMonth: 'الشهر الحالي',
    L10nKeys.previousMonth: 'الشهر اللي فات',
    L10nKeys.nextMonth: 'الشهر الجاي',
    L10nKeys.recentActivity: 'آخر النشاط',
    L10nKeys.selectedMember: 'العضو المختار',
    L10nKeys.selectedPlan: 'الباقة المختارة',
    L10nKeys.receiptNumber: 'رقم الإيصال',
    L10nKeys.copied: 'تم النسخ',
    L10nKeys.paid: 'مدفوع',
    L10nKeys.partial: 'جزئي',
    L10nKeys.unpaid: 'غير مدفوع',
    L10nKeys.cash: 'كاش',
    L10nKeys.card: 'كارت',
    L10nKeys.online: 'أونلاين',
    L10nKeys.wallet: 'محفظة',
    L10nKeys.bankTransfer: 'تحويل بنكي',
    L10nKeys.subscriptionStart: 'بداية الاشتراك',
    L10nKeys.subscriptionEnd: 'نهاية الاشتراك',
    L10nKeys.paidAmount: 'المبلغ المدفوع',
    L10nKeys.remainingAmount: 'المبلغ المتبقي',
    L10nKeys.scannerReady: 'الماسح جاهز',
    L10nKeys.checkedInSuccessfully: 'تم تسجيل الدخول بنجاح',
    L10nKeys.checkedOutSuccessfully: 'تم تسجيل الخروج بنجاح',
    L10nKeys.activeSession: 'جلسة نشطة',
    L10nKeys.checkInTime: 'وقت الدخول',
    L10nKeys.checkOutTime: 'وقت الخروج',
    L10nKeys.memberPhone: 'موبايل العضو',
    L10nKeys.manualAdjustment: 'تعديل يدوي',
    L10nKeys.increase: 'زيادة',
    L10nKeys.decrease: 'تقليل',
    L10nKeys.currentCount: 'العدد الحالي',
    L10nKeys.percentage: 'النسبة',
    L10nKeys.noRecentCheckins: 'مفيش تسجيلات دخول حديثة.',
    L10nKeys.profile: 'الملف',
    L10nKeys.contactDetails: 'بيانات التواصل',
    L10nKeys.memberInformation: 'بيانات العضو',
    L10nKeys.subscriptionDetails: 'تفاصيل الاشتراك',
    L10nKeys.paymentHistory: 'سجل المدفوعات',
    L10nKeys.attendanceSessions: 'جلسات الحضور',
    L10nKeys.legacyCheckinLogs: 'سجل الدخول القديم',
    L10nKeys.currentStatus: 'الحالة الحالية',
    L10nKeys.noPaymentsFound: 'مفيش مدفوعات.',
    L10nKeys.noAttendanceSessionsFound: 'مفيش جلسات حضور.',
    L10nKeys.stillInside: 'لسه جوه',
    L10nKeys.lastCheckout: 'آخر خروج',
    L10nKeys.checkInMethod: 'طريقة الدخول',
    L10nKeys.checkOutMethod: 'طريقة الخروج',
    L10nKeys.duration: 'المدة',
    L10nKeys.createdAt: 'تاريخ الإنشاء',
    L10nKeys.updatedAt: 'تاريخ التحديث',
    L10nKeys.assignedAt: 'تاريخ التخصيص',
    L10nKeys.notAssigned: 'مش متعين',
    L10nKeys.allowed: 'مسموح',
    L10nKeys.blocked: 'ممنوع',
    L10nKeys.warning: 'تنبيه',
    L10nKeys.disabled: 'متوقف',
    L10nKeys.lost: 'مفقود',
    L10nKeys.replaced: 'تم استبداله',
    L10nKeys.title: 'العنوان',
    L10nKeys.category: 'الفئة',
    L10nKeys.quantity: 'الكمية',
    L10nKeys.unitPrice: 'سعر الوحدة',
    L10nKeys.costPrice: 'سعر التكلفة',
    L10nKeys.salePrice: 'سعر البيع',
    L10nKeys.stock: 'المخزون',
    L10nKeys.productCost: 'تكلفة المنتج',
    L10nKeys.operatingExpenses: 'مصروفات التشغيل',
    L10nKeys.membershipRevenue: 'إيرادات العضويات',
    L10nKeys.grossRevenue: 'إجمالي الإيراد',
    L10nKeys.executiveSummary: 'ملخص الإدارة',
    L10nKeys.financialOverview: 'نظرة مالية',
    L10nKeys.monthReport: 'تقرير الشهر',
    L10nKeys.expenseDetails: 'تفاصيل المصروف',
    L10nKeys.payrollDetails: 'تفاصيل المرتب',
    L10nKeys.productDetails: 'تفاصيل المنتج',
    L10nKeys.saleDetails: 'تفاصيل البيع',
    L10nKeys.cancelRecord: 'إلغاء السجل',
    L10nKeys.myMembership: 'عضويتي',
    L10nKeys.subscriptionEnds: 'نهاية الاشتراك',
    L10nKeys.showQrAtReception: 'اعرض الـ QR ده في الريسيبشن',
    L10nKeys.accessWarning: 'تنبيه الدخول',
    L10nKeys.peopleInsideNow: 'أشخاص موجودين دلوقتي',
    L10nKeys.noAttendanceYet: 'مفيش حضور لسه.',
    L10nKeys.memberProfileIncomplete:
        'بيانات الجيم ناقصة. كلم الجيم.',
    L10nKeys.memberProfileNotLinked:
        'ملف العضو مش مربوط بحسابك لسه. كلم الجيم.',
    L10nKeys.memberProfileNotFound:
        'ملف العضو مش موجود. كلم الجيم.',
    L10nKeys.tenantControl: 'التحكم في الجيمات',
    L10nKeys.actionAffectsGymAccess:
        'الإجراء ده بيأثر على دخول الجيم.',
    L10nKeys.gymSuspendedSuccess: 'تم إيقاف الجيم بنجاح.',
    L10nKeys.gymResumedSuccess: 'تم تشغيل الجيم بنجاح.',
    L10nKeys.gymCancelledSuccess: 'تم إلغاء الجيم بنجاح.',
    L10nKeys.archiveMember: 'أرشفة العضو',
    L10nKeys.deactivateMember: 'إيقاف العضو',
    L10nKeys.memberArchivedSuccess: 'تمت أرشفة العضو بنجاح.',
    L10nKeys.memberArchivedMessage: 'العضو ده متأرشف.',
    L10nKeys.archivedCheckinBlocked:
        'مينفعش تسجل دخول لأن حساب العضو متأرشف.',
    L10nKeys.archivePreservesHistory:
        'الإجراء ده مش هيحذف المدفوعات أو الحضور أو السجل.',
  },
};
