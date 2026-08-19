export type ShiftType = 'day' | 'night';
export type AppMode = 'gate' | 'cups' | 'pos' | 'kitchen' | 'admin';
export type KitchenRoute = 'Day shift' | 'Night shift' | 'Bue delivery';

export type ProductCategory = 'Food' | 'Juice' | 'Beverage';

export interface Product {
  id: string;
  name: string;
  description: string;
  price: number;
  category: ProductCategory;
  tone: string;
  emoji: string;
  image?: string;
  isAvailable: boolean;
}

export interface OrderItem extends Product {
  quantity: number;
}

export type PaymentMethod = 'Cash' | 'Transfer' | 'Pay later' | 'Credit' | 'Delivery';

export interface Order {
  id: string;
  shiftId: string;
  cashierName: string;
  items: OrderItem[];
  subtotal: number;
  tax: number;
  total: number;
  paymentMethod: PaymentMethod;
  notes?: string;
  createdAt: string;
}

export interface ShiftExpense {
  id: string;
  shiftId: string;
  category: string;
  description: string;
  amount: number;
  loggedAt: string;
}

export interface CustomerDebt {
  id: string;
  customerName: string;
  note: string;
  cupCount: number;
  pricePerCup: number;
  amount: number; // cupCount * pricePerCup
  isRecovered: boolean;
  shiftIdCreated: string;
  shiftIdRecovered?: string;
  createdAt: string;
  recoveredAt?: string;
}

export interface ShiftSession {
  id: string;
  shiftType: ShiftType;
  cashierName: string;
  openingCups: number;
  status: 'active' | 'closed';
  startedAt: string;
  closedAt?: string;
}

export interface KitchenTicket {
  id: string;
  route: KitchenRoute;
  shiftId?: string;
  items: OrderItem[];
  totalQuantity: number;
  createdAt: string;
}

export interface FoodItemReconciliation {
  id: string;
  name: string;
  emoji?: string;
  kitchenCookedCount: number;
  waiterSoldCount: number;
  variance: number;
}

export interface ShiftReconciliation {
  id: string;
  shiftId: string;
  shiftType: ShiftType;
  cashierName: string;
  
  // Step 1: Sales breakdown
  grossRevenue: number;
  cashSales: number;
  transferSales: number;
  creditSales: number;
  deliverySales: number;
  tipSales: number;
  totalOrdersCount: number;

  // Step 2: Cup inventory count & Food cross-check
  openingCups: number;
  addedCups: number;
  leftoverCups: number;
  calculatedCupsSold: number;
  tabletCupsSold: number;
  cupsVariance: number;

  totalKitchenFoodCooked: number;
  totalWaiterFoodSold: number;
  foodVariance: number;
  foodItemsReconciliation: FoodItemReconciliation[];

  // Step 3: Expenses
  totalExpenses: number;
  expenses: ShiftExpense[];

  // Step 4: Recovered Debts in Cups
  totalRecoveredCups: number;
  totalRecoveredDebts: number;
  recoveredDebts: CustomerDebt[];

  // Step 5: Cash Handover
  netCashToOwner: number;
  shiftNotes: string;
  closedAt: string;
}
