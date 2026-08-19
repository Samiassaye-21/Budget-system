'use client';

import React, { useState, useMemo } from 'react';
import {
  Search, Bell, CircleDollarSign, ChevronRight, Plus, Minus, Trash2,
  WalletCards, Smartphone, ReceiptText, CreditCard, Truck, Sparkles, UserRound, Check,
  Clock, AlertCircle
} from 'lucide-react';
import { Product, OrderItem, PaymentMethod, ShiftSession, Order, CustomerDebt } from '../types/pos';
import { ShiftReconciliationModal } from './ShiftReconciliationModal';
import { PayLaterResolutionModal } from './PayLaterResolutionModal';
import { dataService } from '../lib/dataService';

interface POSWorkspaceProps {
  shiftSession: ShiftSession;
  products: Product[];
  orders: Order[];
  debts: CustomerDebt[];
  onToggleAvailability: (productId: string) => void;
  onFireOrder: (order: Order) => void;
  onUpdateOrders?: (orders: Order[]) => void;
  onAddDebts?: (debts: CustomerDebt[]) => void;
  onCloseShift: () => void;
  onSwitchWorkspace: () => void;
}

export function POSWorkspace({
  shiftSession,
  products,
  orders,
  debts,
  onToggleAvailability,
  onFireOrder,
  onUpdateOrders,
  onAddDebts,
  onCloseShift,
  onSwitchWorkspace,
}: POSWorkspaceProps) {
  const [activeCategory, setActiveCategory] = useState<'Food' | 'Juice'>('Juice');
  const [searchQuery, setSearchQuery] = useState<string>('');
  const [activeOrderItems, setActiveOrderItems] = useState<OrderItem[]>([]);
  const [paymentMethod, setPaymentMethod] = useState<PaymentMethod>('Cash');
  const [orderNotes, setOrderNotes] = useState<string>('');
  const [showReconciliationModal, setShowReconciliationModal] = useState<boolean>(false);
  const [showPayLaterModal, setShowPayLaterModal] = useState<boolean>(false);
  const [orderSuccessMsg, setOrderSuccessMsg] = useState<boolean>(false);

  // Local orders list: starts from the prop (persisted orders) and grows as new orders are fired.
  // This ensures the reconciliation modal ALWAYS sees the full up-to-date list.
  const [localNewOrders, setLocalNewOrders] = useState<Order[]>([]);
  const allShiftOrders = useMemo(() => {
    return [...localNewOrders, ...orders.filter(o => !localNewOrders.find(lo => lo.id === o.id))];
  }, [localNewOrders, orders]);

  // Track unresolved Pay later orders
  const pendingPayLaterOrders = useMemo(() => {
    return allShiftOrders.filter(o => o.paymentMethod === 'Pay later');
  }, [allShiftOrders]);

  // Local customer debts state
  const [currentDebts, setCurrentDebts] = useState<CustomerDebt[]>(debts);

  // Sync if debts prop updates
  React.useEffect(() => {
    setCurrentDebts(debts);
  }, [debts]);

  // Filtered menu products
  const filteredProducts = useMemo(() => {
    return products.filter(
      p => p.category === activeCategory && p.name.toLowerCase().includes(searchQuery.toLowerCase())
    );
  }, [products, activeCategory, searchQuery]);

  // Net Order Financial Totals (NO 15% TAX ADDED - NET TOTAL)
  const subtotal = activeOrderItems.reduce((sum, item) => sum + item.price * item.quantity, 0);
  const total = subtotal;

  // Cup Usage Ticker — use allShiftOrders so count is always current
  const totalJuicesSold = allShiftOrders.reduce((sum, o) => {
    return sum + o.items.filter(i => i.category === 'Juice').reduce((cSum, i) => cSum + i.quantity, 0);
  }, 0);
  const currentJuicesInDraft = activeOrderItems.filter(i => i.category === 'Juice').reduce((sum, i) => sum + i.quantity, 0);
  const totalCupsUsed = totalJuicesSold + currentJuicesInDraft;
  const cupsRemaining = Math.max(0, shiftSession.openingCups - totalCupsUsed);

  // Total Shift Revenue (ETB) — always computed from the full combined list
  const totalShiftRevenue = allShiftOrders.reduce((sum, o) => sum + o.total, 0);

  // Handlers for Order Items
  const handleAddToOrder = (product: Product) => {
    if (!product.isAvailable) return;
    setActiveOrderItems(prev => {
      const existing = prev.find(item => item.id === product.id || item.name === product.name);
      if (existing) {
        return prev.map(item =>
          item.id === product.id || item.name === product.name
            ? { ...item, quantity: item.quantity + 1 }
            : item
        );
      }
      return [...prev, { ...product, quantity: 1 }];
    });
  };

  const handleUpdateQuantity = (id: string, delta: number) => {
    setActiveOrderItems(prev =>
      prev
        .map(item => (item.id === id ? { ...item, quantity: Math.max(0, item.quantity + delta) } : item))
        .filter(item => item.quantity > 0)
    );
  };

  const handleFireOrder = () => {
    if (activeOrderItems.length === 0) return;
    const newOrder: Order = {
      id: `ord-${Date.now()}`,
      shiftId: shiftSession.id,
      cashierName: shiftSession.cashierName || 'ሳራ መኮንን',
      items: [...activeOrderItems],
      subtotal,
      tax: 0,
      total,
      paymentMethod,
      notes: orderNotes,
      createdAt: new Date().toISOString()
    };

    // Add to local list immediately — reconciliation sees it right away
    setLocalNewOrders(prev => [newOrder, ...prev]);
    onFireOrder(newOrder); // also update parent state for persistence
    setActiveOrderItems([]);
    setOrderNotes('');
    setOrderSuccessMsg(true);

    setTimeout(() => setOrderSuccessMsg(false), 1800);
  };

  // Open Reconciliation: enforces resolving any Pay Later orders first
  const handleOpenReconciliation = () => {
    if (pendingPayLaterOrders.length > 0) {
      setShowPayLaterModal(true);
    } else {
      setShowReconciliationModal(true);
    }
  };

  const handleConfirmPayLaterResolutions = async (
    updatedOrders: Order[],
    newDebts: CustomerDebt[]
  ) => {
    // 1. Update local orders list
    setLocalNewOrders(prev => {
      const copy = [...prev];
      updatedOrders.forEach(uo => {
        const idx = copy.findIndex(o => o.id === uo.id);
        if (idx >= 0) {
          copy[idx] = uo;
        } else {
          copy.push(uo);
        }
      });
      return copy;
    });

    // 2. Persist order updates to database/service
    for (const ord of updatedOrders) {
      await dataService.updateOrderPaymentMethod(ord.id, ord.paymentMethod, ord.notes);
    }

    // 3. Persist new customer debts (if any were marked as Credit/Pending)
    for (const debt of newDebts) {
      await dataService.saveCustomerDebt(debt);
    }

    if (newDebts.length > 0) {
      const updatedDebtsList = [...newDebts, ...currentDebts];
      setCurrentDebts(updatedDebtsList);
      if (onAddDebts) {
        onAddDebts(newDebts);
      }
    }

    if (onUpdateOrders) {
      onUpdateOrders(updatedOrders);
    }

    // 4. Close Pay Later modal and open Shift Reconciliation modal seamlessly
    setShowPayLaterModal(false);
    setShowReconciliationModal(true);
  };

  return (
    <main className="pos-shell">
      {/* Toast Overlay for Order Success */}
      {orderSuccessMsg && (
        <div className="fixed inset-0 bg-black/30 z-50 flex items-center justify-center p-4 pointer-events-none">
          <div className="bg-white p-6 rounded-2xl shadow-2xl text-center max-w-sm w-full animate-in zoom-in-95 pointer-events-auto">
            <div className="w-14 h-14 bg-gray-100 text-gray-700 rounded-full flex items-center justify-center mx-auto mb-3">
              <Check className="w-8 h-8" />
            </div>
            <h2 className="text-xl font-bold text-gray-900">ትዕዛዝ ተልኳል!</h2>
            <p className="text-xs text-gray-500 mt-1">ሌላ ትዕዛዝ ለመጨመር ዝግጁ ነው።</p>
          </div>
        </div>
      )}

      {/* Mobile Top Header */}
      <header className="mobile-header flex items-center justify-between p-3 bg-white border-b border-gray-200">
        <div className="flex items-center gap-2" onClick={onSwitchWorkspace}>
          <img src="/logo.jpg" alt="Maraki Logo" className="w-8 h-8 rounded-full object-cover border border-gray-200" />
          <strong className="text-sm font-bold">ማራኪ POS</strong>
        </div>
        <div className="flex items-center gap-2">
          {pendingPayLaterOrders.length > 0 && (
            <button
              onClick={() => setShowPayLaterModal(true)}
              className="px-2.5 py-1 bg-amber-500 text-white text-[11px] font-bold rounded-lg flex items-center gap-1 shadow-sm animate-pulse"
            >
              <Clock className="w-3 h-3" /> {pendingPayLaterOrders.length} Pay Later
            </button>
          )}
          <button
            onClick={handleOpenReconciliation}
            className="px-3 py-1.5 bg-primary text-white text-xs font-bold rounded-lg flex items-center gap-1 shadow-sm"
          >
            <CircleDollarSign className="w-3.5 h-3.5" /> ማጠቃለያ
          </button>
        </div>
      </header>

      {/* Desktop Top Bar */}
      <div className="topbar">
        <div className="brand cursor-pointer" onClick={onSwitchWorkspace}>
          <img src="/logo.jpg" alt="Maraki Logo" className="w-10 h-10 rounded-full object-cover border border-gray-200 shadow-sm" />
          <div>
            <strong>ማራኪ<span>POS</span></strong>
            <small>አዲስ አበባ • ቦሌ ቅርንጫፍ</small>
          </div>
        </div>

        <div className="top-actions">
          {pendingPayLaterOrders.length > 0 && (
            <button
              onClick={() => setShowPayLaterModal(true)}
              className="px-3 py-1.5 bg-amber-50 border border-amber-300 text-amber-900 rounded-lg text-xs font-bold flex items-center gap-1.5 hover:bg-amber-100 transition-colors cursor-pointer"
            >
              <Clock className="w-3.5 h-3.5 text-amber-600" />
              <span>{pendingPayLaterOrders.length} ያልተከፈሉ (Pay Later) ትዕዛዞች</span>
            </button>
          )}

          <div className="shift-badge uppercase font-bold text-xs">
            {shiftSession.shiftType === 'day' ? '☀ የቀን ሺፍት' : '☾ የማታ ሺፍት'}
            <small className="normal-case text-gray-500 font-semibold">{shiftSession.openingCups} የቀሩ ብርጭቆዎች</small>
          </div>

          {/* Highly Visible End of Shift Reconciliation Trigger */}
          <button
            onClick={handleOpenReconciliation}
            className="px-4 py-2 bg-primary hover:bg-primary/90 text-white font-extrabold text-xs rounded-xl shadow-md flex items-center gap-2 transition-all active:scale-95 border border-primary"
          >
            <CircleDollarSign className="w-4 h-4 text-white" />
            <span>የሺፍት ማጠቃለያ (END OF SHIFT RECONCILIATION)</span>
          </button>

          <div className="avatar font-bold bg-gray-100 text-gray-800 border border-gray-200">ሳመ</div>
          <span className="operator">
            ሳራ መኮንን <small>ካሸር (Cashier)</small>
          </span>

          <button onClick={onSwitchWorkspace} className="outline-button text-xs font-semibold hover:bg-gray-50">
            የስራ ቦታዎች (Shift Gate)
          </button>
        </div>
      </div>

      {/* Main Workspace Layout */}
      <div className="workspace">
        {/* Catalog Panel */}
        <section className="catalog-panel">
          <div className="section-heading">
            <div>
              <p className="eyebrow">ካታሎግ / {activeCategory === 'Food' ? 'ምግብ' : 'ትኩስ ጁስ'}</p>
              <h1>{activeCategory === 'Food' ? 'የምግብ ዝርዝር' : 'የትኩስ ጁስ ዝርዝር'}</h1>
            </div>
            <div className="desktop-search">
              <Search className="w-4 h-4 text-gray-400" />
              <input
                placeholder="ምግብ እና ጁስ ይፈልጉ..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
              />
            </div>
          </div>

          {/* Category Cards */}
          <div className="category-cards">
            <button
              className={`category-card ${activeCategory === 'Food' ? 'selected border-primary bg-primary/10 text-primary font-bold' : 'bg-gray-50 border-gray-200 text-gray-700'}`}
              onClick={() => setActiveCategory('Food')}
            >
              <span>🥗</span>
              <strong>የምግብ አቅራቦት (Food)</strong>
              <small>{products.filter(p => p.category === 'Food').length} አይነቶች</small>
            </button>
            <button
              className={`category-card ${activeCategory === 'Juice' ? 'selected border-primary bg-primary/10 text-primary font-bold' : 'bg-gray-50 border-gray-200 text-gray-700'}`}
              onClick={() => setActiveCategory('Juice')}
            >
              <span>🍹</span>
              <strong>ትኩስ ጁሶች (Juice 170 ETB)</strong>
              <small>{products.filter(p => p.category === 'Juice').length} አይነቶች</small>
            </button>
          </div>

          {/* Product Items Grid */}
          <div className="item-grid">
            {filteredProducts.map((product) => (
              <article className={`product-card ${!product.isAvailable ? 'opacity-60' : ''}`} key={product.id}>
                <div className="product-image bg-gray-100 overflow-hidden">
                  {product.image ? (
                    <img
                      src={product.image}
                      alt={product.name}
                      className="w-full h-full object-cover hover:scale-105 transition-transform duration-300"
                    />
                  ) : (
                    <span>{product.emoji}</span>
                  )}
                  {!product.isAvailable && <em className="absolute top-2 left-2 bg-gray-800 text-white text-[9px] font-bold px-2 py-0.5 rounded">አልቆአል</em>}
                </div>
                <div className="product-body">
                  <div>
                    <h3>{product.name}</h3>
                    <p>{product.description}</p>
                  </div>
                  <div className="price-row">
                    <strong>
                      {product.price.toFixed(0)} <small className="currency">ETB</small>
                    </strong>
                    <button
                      className={`stock-toggle ${product.isAvailable ? 'is-available' : ''}`}
                      onClick={() => onToggleAvailability(product.id)}
                      title="Stock Availability"
                    >
                      <span>የለም</span>
                      <span>አለ</span>
                    </button>
                  </div>
                  <button
                    className="add-button cursor-pointer font-bold"
                    disabled={!product.isAvailable}
                    onClick={() => handleAddToOrder(product)}
                  >
                    <Plus className="w-3.5 h-3.5" /> ወደ ማዘዣ ጨምር
                  </button>
                </div>
              </article>
            ))}
          </div>
        </section>

        {/* Active Order Panel */}
        <aside className="order-panel">
          <div className="order-header">
            <div>
              <p className="eyebrow">የአሁኑ ማዘዣ (ACTIVE ORDER)</p>
              <h2>ጠረጴዛ 5 <span>• በአካል</span></h2>
            </div>
          </div>

          <div className="order-meta">
            <span className="flex items-center gap-1"><UserRound className="w-3.5 h-3.5" /> ሳራ መ.</span>
            <span>ትዕዛዝ #{String(orders.length + 1040)}</span>
          </div>

          {/* Itemized Order Lines */}
          <div className="order-items">
            {activeOrderItems.length === 0 ? (
              <div className="text-center py-10 text-gray-400 text-xs">
                ምንም የተመረጠ ማዘዣ የለም። ከካታሎጉ ላይ የመረጡትን ይጫኑ።
              </div>
            ) : (
              activeOrderItems.map((item) => (
                <div className="order-item" key={item.id}>
                  <div className="order-thumb overflow-hidden bg-gray-100">
                    {item.image ? (
                      <img src={item.image} alt={item.name} className="w-full h-full object-cover" />
                    ) : (
                      item.emoji
                    )}
                  </div>
                  <div className="order-item-info">
                    <strong>{item.name}</strong>
                    <div className="quantity">
                      <button onClick={() => handleUpdateQuantity(item.id, -1)}><Minus className="w-3 h-3" /></button>
                      <b>{item.quantity}</b>
                      <button onClick={() => handleUpdateQuantity(item.id, 1)}><Plus className="w-3 h-3" /></button>
                    </div>
                  </div>
                  <strong className="line-price">{(item.price * item.quantity).toFixed(0)} ETB</strong>
                  <button className="delete-item" onClick={() => handleUpdateQuantity(item.id, -item.quantity)}>
                    <Trash2 className="w-3.5 h-3.5 text-gray-400 hover:text-red-500" />
                  </button>
                </div>
              ))
            )}
          </div>

          <textarea
            className="order-notes"
            placeholder="ልዩ ማስታወሻ ይጻፉ..."
            value={orderNotes}
            onChange={(e) => setOrderNotes(e.target.value)}
          />

          <div className="totals">
            <div className="grand-total flex justify-between items-center pt-2">
              <span className="font-bold text-gray-900">ጠቅላላ ክፍያ (Net Amount)</span>
              <strong className="text-2xl font-black text-gray-900">{total.toFixed(0)} ETB</strong>
            </div>
          </div>

          <div className="payment-title">
            <span>የክፍያ መንገድ (PAYMENT METHOD)</span>
            <small>ለመምረጥ ይጫኑ</small>
          </div>

          <div className="payment-grid">
            {[
              ['Cash', WalletCards, 'ጥሬ ገንዘብ'],
              ['Transfer', Smartphone, 'ባንክ ማስተላለፍ'],
              ['Pay later', ReceiptText, 'በኋላ (Pay later)'],
              ['Credit', CreditCard, 'በብድር'],
              ['Delivery', Truck, 'ዴሊቨሪ'],
            ].map(([label, Icon, labelAmharic]) => {
              const IconComp = Icon as React.ElementType;
              return (
                <button
                  key={label as string}
                  className={`${paymentMethod === label ? 'selected' : ''} ${label === 'Pay later' ? 'hover:border-amber-400' : ''}`}
                  onClick={() => setPaymentMethod(label as PaymentMethod)}
                >
                  <IconComp className="w-4 h-4" />
                  <span>{(labelAmharic || label) as string}</span>
                </button>
              );
            })}
          </div>

          <button
            className="fire-button cursor-pointer disabled:opacity-50 font-bold"
            disabled={activeOrderItems.length === 0}
            onClick={handleFireOrder}
          >
            <Sparkles className="w-4 h-4" /> ትዕዛዝ አስተላልፍ (Fire Order) <ChevronRight className="w-4 h-4" />
          </button>
        </aside>
      </div>

      {/* Bottom Status Bar */}
      <div className="status-bar">
        <div className="tables">
          <span className="status-label uppercase font-extrabold text-gray-600">
            {totalCupsUsed} ብርጭቆ ጥቅም ላይ ውሏል / {cupsRemaining} ይቀራል
          </span>
          <span className="table-pill ready uppercase font-bold bg-gray-100 text-gray-800 border border-gray-200">
            {shiftSession.shiftType === 'day' ? 'የቀን' : 'የማታ'} አገልግሎት ክፍት ነው
          </span>
          {pendingPayLaterOrders.length > 0 && (
            <button
              onClick={() => setShowPayLaterModal(true)}
              className="table-pill bg-amber-100 text-amber-900 border border-amber-300 font-bold hover:bg-amber-200 transition-colors cursor-pointer flex items-center gap-1"
            >
              <Clock className="w-3 h-3 text-amber-700" />
              <span>{pendingPayLaterOrders.length} Pay Later ያልተከፈለ</span>
            </button>
          )}
        </div>

        {/* Highly Visible End of Shift Reconciliation Trigger */}
        <button
          className="shift-summary cursor-pointer bg-white border border-gray-300 hover:bg-gray-50 p-2 rounded-xl transition-all shadow-sm"
          onClick={handleOpenReconciliation}
        >
          <CircleDollarSign className="w-6 h-6 text-primary" />
          <span className="flex flex-col text-left">
            <strong className="text-[10px] text-gray-500 font-extrabold uppercase tracking-wider">የሺፍት ማጠቃለያ (RECONCILIATION)</strong>
            <b className="text-xs text-gray-900 font-bold">{totalShiftRevenue.toFixed(0)} ETB የዛሬ ሽያጭ</b>
          </span>
          <ChevronRight className="w-4 h-4 text-gray-400 ml-2" />
        </button>
      </div>

      {/* Pay Later Mandatory Resolution Modal */}
      {showPayLaterModal && (
        <PayLaterResolutionModal
          shiftId={shiftSession.id}
          payLaterOrders={pendingPayLaterOrders}
          onClose={() => setShowPayLaterModal(false)}
          onConfirmResolutions={handleConfirmPayLaterResolutions}
        />
      )}

      {/* Shift Reconciliation Wizard Modal */}
      {showReconciliationModal && (
        <ShiftReconciliationModal
          shiftSession={shiftSession}
          orders={allShiftOrders}
          initialDebts={currentDebts}
          cupsSold={totalCupsUsed}
          kitchenTickets={dataService.getKitchenTickets()}
          onClose={() => setShowReconciliationModal(false)}
          onCompleteReconciliation={(recon) => {
            dataService.saveReconciliation(recon);
            setShowReconciliationModal(false);
            onCloseShift();
          }}
        />
      )}
    </main>
  );
}
