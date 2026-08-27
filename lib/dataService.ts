import { supabase, isSupabaseConfigured } from './supabase';
import {
  Product, Order, ShiftExpense, CustomerDebt, ShiftReconciliation, ShiftSession,
  PaymentMethod, KitchenTicket, KitchenRoute, ShiftType, ManualShiftReconciliation,
  DeliveryRecord, InventoryPurchase, GeneralExpense, SystemConfig
} from '../types/pos';

// EXACT MARAKI FOOD & JUICE CATALOG
export const INITIAL_PRODUCTS: Product[] = [
  // FOOD MENU (16 ITEMS)
  { id: 'f-1', name: 'ማራኪ ኮመቦ ሳላድ', description: 'Maraki combo salad', price: 430, category: 'Food', tone: 'mango', emoji: '🥗', image: 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?auto=format&fit=crop&w=600&q=80', isAvailable: true },
  { id: 'f-2', name: 'ሳላድ', description: 'Fresh garden salad', price: 320, category: 'Food', tone: 'mango', emoji: '🥗', image: 'https://images.unsplash.com/photo-1540420773420-3366772f4999?auto=format&fit=crop&w=600&q=80', isAvailable: true },
  { id: 'f-3', name: 'ፓስታ በሳላድ', description: 'Pasta served with salad', price: 320, category: 'Food', tone: 'mango', emoji: '🍝', image: 'https://images.unsplash.com/photo-1621996346565-e3def616403c?auto=format&fit=crop&w=600&q=80', isAvailable: true },
  { id: 'f-4', name: 'ሩዝ በሳላድ', description: 'Rice served with salad', price: 320, category: 'Food', tone: 'mango', emoji: '🍚', image: 'https://images.unsplash.com/photo-1512058564366-18510be2db19?auto=format&fit=crop&w=600&q=80', isAvailable: true },
  { id: 'f-5', name: 'ፓስታ በአትክልት', description: 'Pasta with vegetables', price: 320, category: 'Food', tone: 'mango', emoji: '🍝', image: 'https://images.unsplash.com/photo-1621996346565-e3def616403c?auto=format&fit=crop&w=600&q=80', isAvailable: true },
  { id: 'f-6', name: 'ሩዝ በአትክልት', description: 'Rice with vegetables', price: 320, category: 'Food', tone: 'mango', emoji: '🍚', image: 'https://images.unsplash.com/photo-1512058564366-18510be2db19?auto=format&fit=crop&w=600&q=80', isAvailable: true },
  { id: 'f-7', name: 'ፓስታ በአንቁላል', description: 'Pasta with egg', price: 320, category: 'Food', tone: 'mango', emoji: '🍝', image: 'https://images.unsplash.com/photo-1525351484163-7529414344d8?auto=format&fit=crop&w=600&q=80', isAvailable: true },
  { id: 'f-8', name: 'ሩዝ በእንቁላል', description: 'Rice with egg', price: 320, category: 'Food', tone: 'mango', emoji: '🍚', image: 'https://images.unsplash.com/photo-1525351484163-7529414344d8?auto=format&fit=crop&w=600&q=80', isAvailable: true },
  { id: 'f-9', name: 'እንቁላል ፍርፍር', description: 'Egg firfir', price: 230, category: 'Food', tone: 'mango', emoji: '🍳', image: 'https://images.unsplash.com/photo-1525351484163-7529414344d8?auto=format&fit=crop&w=600&q=80', isAvailable: true },
  { id: 'f-10', name: 'እንቁላል ስልስ', description: 'Egg sils sauce', price: 230, category: 'Food', tone: 'mango', emoji: '🍳', image: 'https://images.unsplash.com/photo-1525351484163-7529414344d8?auto=format&fit=crop&w=600&q=80', isAvailable: true },
  { id: 'f-11', name: 'እንቁላል ሳንድዊች', description: 'Egg sandwich', price: 120, category: 'Food', tone: 'mango', emoji: '🥪', image: 'https://images.unsplash.com/photo-1528735602780-2552fd46c7af?auto=format&fit=crop&w=600&q=80', isAvailable: true },
  { id: 'f-12', name: 'አትክልት ሳንድዊች', description: 'Vegetable sandwich', price: 100, category: 'Food', tone: 'mango', emoji: '🥪', image: 'https://images.unsplash.com/photo-1540420773420-3366772f4999?auto=format&fit=crop&w=600&q=80', isAvailable: true },
  { id: 'f-13', name: 'ፍሩት ፓንች', description: 'Fresh fruit punch bowl', price: 320, category: 'Food', tone: 'mango', emoji: '🍹', image: 'https://images.unsplash.com/photo-1490474418585-ba9bad8fd0ea?auto=format&fit=crop&w=600&q=80', isAvailable: true },
  { id: 'f-14', name: 'ፍርፍር', description: 'Traditional firfir', price: 200, category: 'Food', tone: 'mango', emoji: '🍲', image: 'https://images.unsplash.com/photo-1546833999-b9f581a1996d?auto=format&fit=crop&w=600&q=80', isAvailable: true },
  { id: 'f-15', name: 'ፓስታ በስጎ', description: 'Pasta with sauce', price: 200, category: 'Food', tone: 'mango', emoji: '🍝', image: 'https://images.unsplash.com/photo-1621996346565-e3def616403c?auto=format&fit=crop&w=600&q=80', isAvailable: true },
  { id: 'f-16', name: 'ቴስቲሶያ', description: 'Tasty soya', price: 200, category: 'Food', tone: 'mango', emoji: '🍛', image: 'https://images.unsplash.com/photo-1546833999-b9f581a1996d?auto=format&fit=crop&w=600&q=80', isAvailable: true },

  // JUICE MENU (ALL 170 ETB)
  { id: 'j-1', name: 'Avocado (አቮካዶ)', description: 'Fresh creamy avocado juice', price: 170, category: 'Juice', tone: 'mango', emoji: '🥑', image: '/products/avocado.png', isAvailable: true },
  { id: 'j-2', name: 'Avocado with Mango (አቮካዶ ከማንጎ ጋር)', description: 'Layered avocado & mango juice', price: 170, category: 'Juice', tone: 'mango', emoji: '🥭', image: '/products/maraki_special.png', isAvailable: true },
  { id: 'j-3', name: 'Spris (ስፕሪስ ጁስ)', description: 'Mixed layered sprize juice', price: 170, category: 'Juice', tone: 'mango', emoji: '🍹', image: '/products/maraki_special.png', isAvailable: true },
  { id: 'j-4', name: 'Milk Shake (ሚልካ ሼክ)', description: 'Creamy cold milk shake smoothie', price: 170, category: 'Juice', tone: 'mango', emoji: '🥤', image: 'https://images.unsplash.com/photo-1572490122747-3968b75cc699?auto=format&fit=crop&w=600&q=80', isAvailable: true },
  { id: 'j-5', name: 'Mango (ማንጎ ጁስ)', description: 'Pure organic fresh mango juice', price: 170, category: 'Juice', tone: 'mango', emoji: '🥭', image: 'https://images.unsplash.com/photo-1546173159-315724a31696?auto=format&fit=crop&w=600&q=80', isAvailable: true },
  { id: 'j-6', name: 'Papaya Juice (ፓፓያ ጁስ)', description: 'Fresh papaya smoothie', price: 170, category: 'Juice', tone: 'mango', emoji: '🥭', image: 'https://images.unsplash.com/photo-1553530666-ba11a7da3888?auto=format&fit=crop&w=600&q=80', isAvailable: true },
  { id: 'j-7', name: 'Strawberry Juice (ስትሮቤሪ ጁስ)', description: 'Fresh strawberry blend', price: 170, category: 'Juice', tone: 'mango', emoji: '🍓', image: 'https://images.unsplash.com/photo-1553530666-ba11a7da3888?auto=format&fit=crop&w=600&q=80', isAvailable: true },
  { id: 'j-8', name: 'Pineapple Juice (ፓይናፕል ጁስ)', description: 'Fresh pressed pineapple juice', price: 170, category: 'Juice', tone: 'mango', emoji: '🍍', image: 'https://images.unsplash.com/photo-1546173159-315724a31696?auto=format&fit=crop&w=600&q=80', isAvailable: true },
  { id: 'j-9', name: 'Watermelon Juice (ሐብሐብ ጁስ)', description: 'Cold fresh watermelon juice', price: 170, category: 'Juice', tone: 'mango', emoji: '🍉', image: 'https://images.unsplash.com/photo-1553530666-ba11a7da3888?auto=format&fit=crop&w=600&q=80', isAvailable: true },
];

// CUP-BASED CUSTOMER CREDIT DEBTS (Initial empty pool)
export const INITIAL_DEBTS: CustomerDebt[] = [];

class DataService {
  private products: Product[] = INITIAL_PRODUCTS;
  private debts: CustomerDebt[] = INITIAL_DEBTS;
  private kitchenTickets: KitchenTicket[] = [];
  private lastLeftoverCups: number = 120;

  getKitchenTickets(route?: KitchenRoute): KitchenTicket[] {
    if (typeof window !== 'undefined') {
      const stored = localStorage.getItem('maraki_kitchen_tickets');
      if (stored) {
        try {
          this.kitchenTickets = JSON.parse(stored);
        } catch (e) {
          console.error('Error parsing stored kitchen tickets:', e);
        }
      }
    }
    if (route) {
      return this.kitchenTickets.filter(t => t.route === route);
    }
    return this.kitchenTickets;
  }

  async saveKitchenTicket(ticket: KitchenTicket): Promise<KitchenTicket> {
    this.kitchenTickets.push(ticket);
    if (typeof window !== 'undefined') {
      localStorage.setItem('maraki_kitchen_tickets', JSON.stringify(this.kitchenTickets));
    }
    return ticket;
  }

  clearKitchenTickets(): void {
    this.kitchenTickets = [];
    if (typeof window !== 'undefined') {
      localStorage.removeItem('maraki_kitchen_tickets');
    }
  }

  getLastLeftoverCups(): number {
    if (typeof window !== 'undefined') {
      const stored = localStorage.getItem('maraki_last_leftover_cups');
      if (stored) return Number(stored);
    }
    return this.lastLeftoverCups;
  }

  setLastLeftoverCups(cups: number): void {
    this.lastLeftoverCups = cups;
    if (typeof window !== 'undefined') {
      localStorage.setItem('maraki_last_leftover_cups', String(cups));
    }
  }

  /** Returns today's date string yyyy-mm-dd */
  private todayStr(): string {
    return new Date().toISOString().slice(0, 10);
  }

  /** Check whether the cup setup has already been confirmed for today */
  isCupSetupDoneToday(): boolean {
    if (typeof window !== 'undefined') {
      const date = localStorage.getItem('maraki_cup_setup_date');
      return date === this.todayStr();
    }
    return false;
  }

  /** Mark cup setup as done for today */
  markCupSetupDoneToday(): void {
    if (typeof window !== 'undefined') {
      localStorage.setItem('maraki_cup_setup_date', this.todayStr());
    }
  }

  async getProducts(): Promise<Product[]> {
    if (isSupabaseConfigured && supabase) {
      const { data, error } = await supabase.from('products').select('*');
      if (!error && data && data.length > 0) {
        return data.map((item: any) => ({
          id: item.id,
          name: item.name,
          description: item.description || '',
          price: Number(item.price),
          category: item.category,
          tone: item.tone || 'mango',
          emoji: item.emoji || '🍹',
          image: item.image || undefined,
          isAvailable: item.is_available ?? true
        }));
      }
    }
    return this.products;
  }

  getProductsSync(): Product[] {
    return this.products;
  }

  async saveProduct(product: Product): Promise<Product> {
    if (isSupabaseConfigured && supabase) {
      const dbPayload = {
        name: product.name,
        description: product.description,
        price: product.price,
        category: product.category,
        tone: product.tone,
        emoji: product.emoji,
        image: product.image,
        is_available: product.isAvailable,
      };
      
      if (product.id && product.id.length > 5) {
        await supabase.from('products').update(dbPayload).eq('id', product.id);
      } else {
        const { data } = await supabase.from('products').insert([dbPayload]).select().single();
        if (data) product.id = data.id;
      }
    } else {
      const existingIdx = this.products.findIndex(p => p.id === product.id || p.name === product.name);
      if (existingIdx >= 0) {
        this.products[existingIdx] = product;
      } else {
        const newProduct = { ...product, id: product.id || String(Date.now()) };
        this.products.push(newProduct);
        return newProduct;
      }
    }
    return product;
  }

  async deleteProduct(id: string): Promise<void> {
    if (isSupabaseConfigured && supabase) {
      await supabase.from('products').delete().eq('id', id);
    } else {
      this.products = this.products.filter(p => p.id !== id);
    }
  }

  async saveOrder(order: Order): Promise<void> {
    if (isSupabaseConfigured && supabase) {
      await supabase.from('orders').insert([{
        shift_id: order.shiftId,
        cashier_name: order.cashierName,
        items: order.items,
        subtotal: order.subtotal,
        tax: order.tax,
        total: order.total,
        payment_method: order.paymentMethod,
        notes: order.notes || ''
      }]);
    }
  }

  async updateOrderPaymentMethod(orderId: string, paymentMethod: PaymentMethod, notes?: string): Promise<void> {
    if (isSupabaseConfigured && supabase) {
      const payload: any = { payment_method: paymentMethod };
      if (notes !== undefined) payload.notes = notes;
      await supabase.from('orders').update(payload).eq('id', orderId);
    }
  }

  async saveCustomerDebt(debt: CustomerDebt): Promise<CustomerDebt> {
    if (isSupabaseConfigured && supabase) {
      const { data } = await supabase.from('customer_debts').insert([{
        customer_name: debt.customerName,
        note: debt.note || '',
        cup_count: debt.cupCount,
        price_per_cup: debt.pricePerCup,
        amount: debt.amount,
        is_recovered: debt.isRecovered,
        shift_id_created: debt.shiftIdCreated,
      }]).select().single();

      if (data) debt.id = data.id;
    } else {
      const newDebt = { ...debt, id: debt.id || `deb-${Date.now()}` };
      this.debts = [newDebt, ...this.debts];
      return newDebt;
    }
    return debt;
  }

  async saveReconciliation(recon: ShiftReconciliation): Promise<void> {
    this.setLastLeftoverCups(recon.leftoverCups);

    if (isSupabaseConfigured && supabase) {
      await supabase.from('shift_reconciliations').insert([{
        shift_id: recon.shiftId,
        shift_type: recon.shiftType,
        cashier_name: recon.cashierName,
        gross_revenue: recon.grossRevenue,
        cash_sales: recon.cashSales,
        transfer_sales: recon.transferSales,
        credit_sales: recon.creditSales,
        delivery_sales: recon.deliverySales,
        tip_sales: recon.tipSales,
        total_orders_count: recon.totalOrdersCount,
        opening_cups: recon.openingCups,
        added_cups: recon.addedCups,
        leftover_cups: recon.leftoverCups,
        calculated_cups_sold: recon.calculatedCupsSold,
        tablet_cups_sold: recon.tabletCupsSold,
        cups_variance: recon.cupsVariance,
        total_expenses: recon.totalExpenses,
        total_recovered_debts: recon.totalRecoveredDebts,
        net_cash_to_owner: recon.netCashToOwner,
        shift_notes: recon.shiftNotes,
      }]);
      
      // Update shift status to closed
      await supabase.from('shifts').update({
        status: 'closed',
        closed_at: new Date().toISOString()
      }).eq('id', recon.shiftId);
    }
  }

  async getCustomerDebts(): Promise<CustomerDebt[]> {
    if (isSupabaseConfigured && supabase) {
      const { data, error } = await supabase.from('customer_debts').select('*');
      if (!error && data) {
        return data.map((item: any) => ({
          id: item.id,
          customerName: item.customer_name,
          note: item.note || '',
          cupCount: Number(item.cup_count || 1),
          pricePerCup: Number(item.price_per_cup || 170),
          amount: Number(item.amount || (Number(item.cup_count || 1) * 170)),
          isRecovered: item.is_recovered,
          shiftIdCreated: item.shift_id_created || '',
          createdAt: item.created_at
        }));
      }
    }
    return this.debts;
  }

  async markDebtRecovered(debtId: string, shiftId: string): Promise<void> {
    if (isSupabaseConfigured && supabase) {
      await supabase.from('customer_debts').update({
        is_recovered: true,
        shift_id_recovered: shiftId,
        recovered_at: new Date().toISOString()
      }).eq('id', debtId);
    } else {
      const debt = this.debts.find(d => d.id === debtId);
      if (debt) {
        debt.isRecovered = true;
        debt.shiftIdRecovered = shiftId;
        debt.recoveredAt = new Date().toISOString();
      }
    }
  }

  getDebts(): CustomerDebt[] {
    if (typeof window !== 'undefined') {
      const stored = localStorage.getItem('maraki_debts');
      if (stored) {
        try {
          return JSON.parse(stored);
        } catch (e) {
          console.error('Error parsing debts:', e);
        }
      }
    }
    return this.debts;
  }

  createDebt(debt: CustomerDebt): CustomerDebt[] {
    const list = this.getDebts();
    const updated = [debt, ...list];
    this.debts = updated;
    if (typeof window !== 'undefined') {
      localStorage.setItem('maraki_debts', JSON.stringify(updated));
    }
    this.saveCustomerDebt(debt);
    return updated;
  }

  recoverDebt(debtId: string, shiftId: string): CustomerDebt[] {
    const list = this.getDebts();
    const updated = list.map(d => d.id === debtId ? { ...d, isRecovered: true, shiftIdRecovered: shiftId, recoveredAt: new Date().toISOString() } : d);
    this.debts = updated;
    if (typeof window !== 'undefined') {
      localStorage.setItem('maraki_debts', JSON.stringify(updated));
    }
    this.markDebtRecovered(debtId, shiftId);
    return updated;
  }

  getOrders(): Order[] {
    if (typeof window !== 'undefined') {
      const stored = localStorage.getItem('maraki_orders');
      if (stored) {
        try {
          return JSON.parse(stored);
        } catch (e) {
          console.error('Error parsing orders:', e);
        }
      }
    }
    return [];
  }

  getManualReconciliationsSync(): ManualShiftReconciliation[] {
    if (typeof window !== 'undefined') {
      const stored = localStorage.getItem('maraki_manual_reconciliations');
      if (stored) {
        try {
          return JSON.parse(stored);
        } catch (e) {
          console.error('Error parsing stored manual reconciliations:', e);
        }
      }
    }
    return [];
  }

  getKitchenTicketsByDateAndShift(dateStr: string, shiftType: ShiftType): KitchenTicket[] {
    const allTickets = this.getKitchenTickets();
    const targetRoute = shiftType === 'day' ? 'Day shift' : 'Night shift';
    
    return allTickets.filter(ticket => {
      // Check date matching YYYY-MM-DD
      const ticketDate = ticket.createdAt ? ticket.createdAt.slice(0, 10) : '';
      const isDateMatch = ticketDate === dateStr || !ticket.createdAt; // match date or fallback
      const isRouteMatch = ticket.route === targetRoute;
      return isDateMatch && isRouteMatch;
    });
  }

  async saveManualReconciliation(recon: ManualShiftReconciliation): Promise<ManualShiftReconciliation> {
    this.setLastLeftoverCups(recon.leftoverCups);

    // Save newly entered pending payments (debts)
    if (recon.pendingPayments && recon.pendingPayments.length > 0) {
      for (const p of recon.pendingPayments) {
        if (p.customerName && p.amount > 0) {
          const newDebt: CustomerDebt = {
            id: p.id || `deb-${Date.now()}-${Math.random().toString(36).substr(2, 4)}`,
            customerName: p.customerName,
            note: p.note || `Manual entry - ${recon.shiftDate} (${recon.shiftType})`,
            cupCount: Math.round(p.amount / 170) || 1,
            pricePerCup: 170,
            amount: p.amount,
            isRecovered: false,
            shiftIdCreated: recon.shiftId || `manual-${recon.shiftDate}`,
            createdAt: new Date(`${recon.shiftDate}T12:00:00`).toISOString()
          };
          await this.saveCustomerDebt(newDebt);
        }
      }
    }

    // Mark recovered debts if any
    if (recon.recoveredPayments && recon.recoveredPayments.length > 0) {
      for (const r of recon.recoveredPayments) {
        if (r.debtId) {
          await this.markDebtRecovered(r.debtId, recon.shiftId || `manual-${recon.shiftDate}`);
        }
      }
    }

    if (isSupabaseConfigured && supabase) {
      const payload: any = {
        id: recon.id || `recon-${Date.now()}`,
        shift_id: recon.shiftId || `manual-${recon.shiftDate}-${recon.shiftType}`,
        shift_type: recon.shiftType,
        cashier_name: recon.cashierName,
        gross_revenue: recon.grossRevenue,
        cash_sales: recon.cashSales,
        transfer_sales: recon.transferSales,
        credit_sales: recon.creditSales,
        delivery_sales: recon.deliverySales,
        tip_sales: recon.tipSales,
        total_orders_count: recon.totalOrdersCount,
        opening_cups: recon.openingCups,
        added_cups: recon.addedCups,
        leftover_cups: recon.leftoverCups,
        calculated_cups_sold: recon.calculatedCupsSold,
        tablet_cups_sold: recon.tabletCupsSold,
        cups_variance: recon.cupsVariance,
        total_kitchen_food_cooked: recon.totalKitchenFoodCooked || 0,
        total_waiter_food_sold: recon.totalWaiterFoodSold || 0,
        food_variance: recon.foodVariance || 0,
        total_expenses: recon.totalExpenses,
        total_recovered_cups: recon.totalRecoveredCups || 0,
        total_recovered_debts: recon.totalRecoveredDebts,
        net_cash_to_owner: recon.netCashToOwner,
        shift_notes: recon.shiftNotes || '',
        closed_at: new Date().toISOString(),
        created_at: new Date().toISOString(),
        // Extended manual fields
        entry_mode: 'manual',
        shift_date: recon.shiftDate,
        juice_breakdown: recon.juiceBreakdown || [],
        food_box_inventory: recon.foodBoxInventory || [],
        food_sold_breakdown: recon.foodSoldBreakdown || [],
        transfer_records: recon.transferRecords || [],
        pending_payments: recon.pendingPayments || [],
        recovered_payments: recon.recoveredPayments || [],
        kitchen_data_found: recon.kitchenDataFound ?? false
      };

      try {
        await supabase.from('shift_reconciliations').insert([payload]);
      } catch (err) {
        console.error('Error inserting manual reconciliation to Supabase:', err);
      }
    }

    // Always keep a local copy
    if (typeof window !== 'undefined') {
      try {
        const stored = localStorage.getItem('maraki_manual_reconciliations');
        const list: ManualShiftReconciliation[] = stored ? JSON.parse(stored) : [];
        list.unshift(recon);
        localStorage.setItem('maraki_manual_reconciliations', JSON.stringify(list));
      } catch (e) {
        console.error('Error saving manual reconciliation to localStorage:', e);
      }
    }

    return recon;
  }

  async getManualReconciliations(): Promise<ManualShiftReconciliation[]> {
    if (isSupabaseConfigured && supabase) {
      try {
        const { data, error } = await supabase
          .from('shift_reconciliations')
          .select('*')
          .order('created_at', { ascending: false });

        if (!error && data && data.length > 0) {
          return data.map((item: any) => ({
            id: item.id,
            shiftId: item.shift_id,
            shiftType: item.shift_type,
            cashierName: item.cashier_name,
            grossRevenue: Number(item.gross_revenue || 0),
            cashSales: Number(item.cash_sales || 0),
            transferSales: Number(item.transfer_sales || 0),
            creditSales: Number(item.credit_sales || 0),
            deliverySales: Number(item.delivery_sales || 0),
            tipSales: Number(item.tip_sales || 0),
            totalOrdersCount: Number(item.total_orders_count || 0),
            openingCups: Number(item.opening_cups || 0),
            addedCups: Number(item.added_cups || 0),
            leftoverCups: Number(item.leftover_cups || 0),
            calculatedCupsSold: Number(item.calculated_cups_sold || 0),
            tabletCupsSold: Number(item.tablet_cups_sold || 0),
            cupsVariance: Number(item.cups_variance || 0),
            totalKitchenFoodCooked: Number(item.total_kitchen_food_cooked || 0),
            totalWaiterFoodSold: Number(item.total_waiter_food_sold || 0),
            foodVariance: Number(item.food_variance || 0),
            foodItemsReconciliation: item.food_items_reconciliation || [],
            totalExpenses: Number(item.total_expenses || 0),
            expenses: item.expenses || [],
            totalRecoveredCups: Number(item.total_recovered_cups || 0),
            totalRecoveredDebts: Number(item.total_recovered_debts || 0),
            recoveredDebts: item.recovered_debts || [],
            netCashToOwner: Number(item.net_cash_to_owner || 0),
            shiftNotes: item.shift_notes || '',
            closedAt: item.closed_at || item.created_at,
            entryMode: (item.entry_mode === 'auto' ? 'auto' : 'manual') as 'manual',
            shiftDate: item.shift_date || item.created_at?.slice(0, 10) || new Date().toISOString().slice(0, 10),
            juiceBreakdown: item.juice_breakdown || [],
            foodBoxInventory: item.food_box_inventory || [],
            foodSoldBreakdown: item.food_sold_breakdown || [],
            transferRecords: item.transfer_records || [],
            pendingPayments: item.pending_payments || [],
            recoveredPayments: item.recovered_payments || [],
            kitchenDataFound: item.kitchen_data_found ?? false
          }));
        }
      } catch (err) {
        console.error('Error fetching manual reconciliations from Supabase:', err);
      }
    }

    // Local fallback
    if (typeof window !== 'undefined') {
      const stored = localStorage.getItem('maraki_manual_reconciliations');
      if (stored) {
        try {
          return JSON.parse(stored);
        } catch (e) {
          console.error('Error parsing stored manual reconciliations:', e);
        }
      }
    }
    return [];
  }

  // --- DELIVERY RECORDS ---
  getDeliveryRecords(): DeliveryRecord[] {
    if (typeof window !== 'undefined') {
      const stored = localStorage.getItem('maraki_delivery_records');
      if (stored) {
        try {
          return JSON.parse(stored);
        } catch (e) {
          console.error('Error parsing delivery records:', e);
        }
      }
    }
    return [
      { id: 'del-1', partnerName: 'BeU Delivery (ቢዩ ዴሊቨሪ)', orderCount: 6, amount: 1680, isSettled: false, shiftType: 'day', date: new Date().toISOString().slice(0, 10), notes: 'Pending weekly settlement' },
      { id: 'del-2', partnerName: 'Direct Rider - ዳዊት (Dawit)', orderCount: 3, amount: 840, isSettled: true, shiftType: 'day', date: new Date(Date.now() - 86400000).toISOString().slice(0, 10), settledAt: new Date().toISOString(), notes: 'Cash settled' },
    ];
  }

  saveDeliveryRecord(record: DeliveryRecord) {
    const list = this.getDeliveryRecords();
    const existingIdx = list.findIndex(r => r.id === record.id);
    let updated: DeliveryRecord[];
    if (existingIdx >= 0) {
      updated = list.map(r => r.id === record.id ? record : r);
    } else {
      updated = [record, ...list];
    }
    if (typeof window !== 'undefined') {
      localStorage.setItem('maraki_delivery_records', JSON.stringify(updated));
    }
    return updated;
  }

  settleDeliveryRecord(id: string) {
    const list = this.getDeliveryRecords();
    const updated = list.map(r => r.id === id ? { ...r, isSettled: true, settledAt: new Date().toISOString() } : r);
    if (typeof window !== 'undefined') {
      localStorage.setItem('maraki_delivery_records', JSON.stringify(updated));
    }
    return updated;
  }

  // --- INVENTORY PURCHASES ---
  getPurchases(): InventoryPurchase[] {
    if (typeof window !== 'undefined') {
      const stored = localStorage.getItem('maraki_purchases');
      if (stored) {
        try {
          return JSON.parse(stored);
        } catch (e) {
          console.error('Error parsing purchases:', e);
        }
      }
    }
    return [
      { id: 'pur-1', itemName: 'አቮካዶ (Avocado)', category: 'Fruits', quantity: 50, unit: 'kg', unitPrice: 120, totalCost: 6000, date: new Date().toISOString().slice(0, 10), purchasedBy: 'አበበ', notes: 'Fresh Grade A' },
      { id: 'pur-2', itemName: 'ማንጎ (Mango)', category: 'Fruits', quantity: 40, unit: 'kg', unitPrice: 140, totalCost: 5600, date: new Date().toISOString().slice(0, 10), purchasedBy: 'አበበ', notes: 'Ripe mangoes' },
      { id: 'pur-3', itemName: 'የጁስ ኩባያ (Takeaway Cups & Straws)', category: 'Packaging', quantity: 500, unit: 'piece', unitPrice: 6, totalCost: 3000, date: new Date().toISOString().slice(0, 10), purchasedBy: 'ሳራ', notes: '500ml cups' },
    ];
  }

  savePurchase(purchase: InventoryPurchase) {
    const list = this.getPurchases();
    const updated = [purchase, ...list];
    if (typeof window !== 'undefined') {
      localStorage.setItem('maraki_purchases', JSON.stringify(updated));
    }
    return updated;
  }

  deletePurchase(id: string) {
    const list = this.getPurchases();
    const updated = list.filter(p => p.id !== id);
    if (typeof window !== 'undefined') {
      localStorage.setItem('maraki_purchases', JSON.stringify(updated));
    }
    return updated;
  }

  // --- GENERAL EXPENSES ---
  getGeneralExpenses(): GeneralExpense[] {
    if (typeof window !== 'undefined') {
      const stored = localStorage.getItem('maraki_general_expenses');
      if (stored) {
        try {
          return JSON.parse(stored);
        } catch (e) {
          console.error('Error parsing general expenses:', e);
        }
      }
    }
    return [
      { id: 'gexp-1', category: 'Rent', description: 'የሱቅ ኪራይ ወርሃዊ ክፍያ (Shop monthly rent)', amount: 25000, date: new Date().toISOString().slice(0, 7) + '-01', paidFrom: 'Bank / Telebirr' },
      { id: 'gexp-2', category: 'Utilities', description: 'የኤሌክትሪክና የውሃ ክፍያ (Electricity & Water)', amount: 2800, date: new Date().toISOString().slice(0, 7) + '-05', paidFrom: 'Bank / Telebirr' },
    ];
  }

  saveGeneralExpense(expense: GeneralExpense) {
    const list = this.getGeneralExpenses();
    const updated = [expense, ...list];
    if (typeof window !== 'undefined') {
      localStorage.setItem('maraki_general_expenses', JSON.stringify(updated));
    }
    return updated;
  }

  deleteGeneralExpense(id: string) {
    const list = this.getGeneralExpenses();
    const updated = list.filter(e => e.id !== id);
    if (typeof window !== 'undefined') {
      localStorage.setItem('maraki_general_expenses', JSON.stringify(updated));
    }
    return updated;
  }

  // --- SYSTEM CONFIG ---
  getConfig(): { dayShiftWorkerName: string; nightShiftWorkerName: string; juiceUnitPrice: number; currency: string } {
    if (typeof window !== 'undefined') {
      const stored = localStorage.getItem('maraki_system_config');
      if (stored) {
        try {
          return JSON.parse(stored);
        } catch (e) {
          console.error('Error parsing system config:', e);
        }
      }
    }
    return {
      dayShiftWorkerName: 'ሳራ መኮንን (Sara Mekonnen)',
      nightShiftWorkerName: 'ዮናስ ታደሰ (Yonas Tadesse)',
      juiceUnitPrice: 170,
      currency: 'ETB'
    };
  }

  saveConfig(config: { dayShiftWorkerName: string; nightShiftWorkerName: string; juiceUnitPrice: number; currency: string }) {
    if (typeof window !== 'undefined') {
      localStorage.setItem('maraki_system_config', JSON.stringify(config));
    }
    return config;
  }
}

export const dataService = new DataService();

export function getEthiopianMonthName(dateStr: string): string {
  const d = new Date(dateStr);
  const m = d.getMonth(); // 0-11
  const ethMonths = [
    'ጥር / ታኅሣሥ', 'የካቲት', 'መጋቢት', 'ሚያዝያ', 'ግንቦት', 'ሰኔ',
    'ሐምሌ', 'ነሐሴ', 'መስከረም', 'ጥቅምት', 'ኅዳር', 'ታኅሣሥ'
  ];
  return ethMonths[m] || 'ወር';
}


