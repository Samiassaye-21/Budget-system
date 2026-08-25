import { supabase, isSupabaseConfigured } from './supabase';
import { Product, Order, ShiftExpense, CustomerDebt, ShiftReconciliation, ShiftSession, PaymentMethod, KitchenTicket, KitchenRoute } from '../types/pos';

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

// CUP-BASED CUSTOMER CREDIT DEBTS (Price per cup: 170 ETB)
export const INITIAL_DEBTS: CustomerDebt[] = [
  { id: 'deb-1', customerName: 'አበበ ቢቂላ (Abebe Bikila)', note: 'የትላንትና የቢሮ ጁስ አዳሪ (Adari)', cupCount: 5, pricePerCup: 170, amount: 850, isRecovered: false, shiftIdCreated: 'prev-shift-1', createdAt: new Date(Date.now() - 86400000).toISOString() },
  { id: 'deb-2', customerName: 'ትዕግስት ኃይሌ (Tigist Haile)', note: 'የምሳ ጁስ ማዘዣ አዳሪ (Adari)', cupCount: 3, pricePerCup: 170, amount: 510, isRecovered: false, shiftIdCreated: 'prev-shift-2', createdAt: new Date(Date.now() - 172800000).toISOString() },
  { id: 'deb-3', customerName: 'ከበደ ታሰሰ (Kebede Tassew)', note: 'የካፌ ዴሊቨሪ ጁስ አዳሪ (Adari)', cupCount: 8, pricePerCup: 170, amount: 1360, isRecovered: false, shiftIdCreated: 'prev-shift-3', createdAt: new Date(Date.now() - 259200000).toISOString() },
];

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
}

export const dataService = new DataService();
