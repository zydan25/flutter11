export interface OperationItem {
  id: string | number;
  operationNumber?: string;
  phone?: string;
  phoneNumber?: string;
  mobile?: string;
  customerName?: string;
  operatorName?: string;
  service?: string;
  packageName?: string;
  item_name?: string;
  amount: number | string;
  fee?: number;
  totalCost?: number;
  balanceBefore?: number;
  balanceAfter?: number;
  date?: string;
  created_at?: string;
  time?: string;
  status: "success" | "pending" | "failed" | string;
  statusText?: string;
  isRealVerified?: boolean;
  orderNumber?: string;
  transid?: string | number;
  transId?: string | number;
  provider_transaction_id?: string | number;
  currency?: string;
  notes?: string;
  type?: string;
}

export interface StatementEntry {
  id: string;
  date: string;
  time: string;
  type: "deposit" | "payment" | "transfer_out" | "transfer_in" | "fee" | string;
  title: string;
  description: string;
  debit: number;
  credit: number;
  balance: number;
  refNumber: string;
}

export interface UserProfile {
  id: number;
  phone: string;
  firstName?: string;
  lastName?: string;
  first_name?: string;
  middle_name?: string;
  third_name?: string;
  last_name?: string;
  fullName?: string;
  governorate?: string;
  role?: string;
  pointsBalance?: number;
  points_balance?: number;
  balanceYer?: number;
  balanceSar?: number;
  balanceUsd?: number;
  balance?: number;
  verified?: boolean;
  avatar?: string | null;
  account_type?: string;
}

export interface StoreProduct {
  id: number;
  name: string;
  price: number;
  salePrice?: number;
  storeName: string;
  category: string;
  image: string;
  rating: number;
  stock: number;
  sku?: string;
  brand?: string;
  description?: string;
  isTrending?: boolean;
}

export interface UserAddress {
  id: string | number;
  title?: string;
  recipientName?: string;
  governorate?: string;
  city: string;
  district?: string;
  streetDetails: string;
  phone: string;
  notes?: string;
  isDefault?: boolean;
}

export interface StoreOrder {
  id: number;
  orderNumber: string;
  total: number;
  status: string;
  statusText: string;
  date: string;
  vendorName: string;
  shippingAddress?: string;
  canEdit?: boolean;
  items: Array<{
    id: number;
    productName: string;
    productImage: string;
    quantity: number;
    price: number;
  }>;
}

export interface CartItem {
  product: StoreProduct;
  quantity: number;
}
