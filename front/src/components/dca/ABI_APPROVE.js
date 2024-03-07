export const ABI_APPROVE = [
	{
		constant: true,
		inputs: [],
		name: 'name',
		outputs: [
			{
				name: '',
				type: 'string',
			},
		],
		payable: false,
		stateMutability: 'view',
		type: 'function',
	},
	{
		constant: false,
		inputs: [
			{
				name: 'spender',
				type: 'address',
			},
			{
				name: 'value',
				type: 'uint256',
			},
		],
		name: 'approve',
		outputs: [
			{
				name: '',
				type: 'bool',
			},
		],
		payable: false,
		stateMutability: 'nonpayable',
		type: 'function',
	},
	{
		constant: true,
		inputs: [],
		name: 'totalSupply',
		outputs: [
			{
				name: '',
				type: 'uint256',
			},
		],
		payable: false,
		stateMutability: 'view',
		type: 'function',
	},
	{
		constant: false,
		inputs: [
			{
				name: 'sender',
				type: 'address',
			},
			{
				name: 'recipient',
				type: 'address',
			},
			{
				name: 'amount',
				type: 'uint256',
			},
		],
		name: 'transferFrom',
		outputs: [
			{
				name: '',
				type: 'bool',
			},
		],
		payable: false,
		stateMutability: 'nonpayable',
		type: 'function',
	},
	{
		constant: true,
		inputs: [],
		name: 'decimals',
		outputs: [
			{
				name: '',
				type: 'uint8',
			},
		],
		payable: false,
		stateMutability: 'view',
		type: 'function',
	},
	{
		constant: false,
		inputs: [
			{
				name: 'spender',
				type: 'address',
			},
			{
				name: 'addedValue',
				type: 'uint256',
			},
		],
		name: 'increaseAllowance',
		outputs: [
			{
				name: '',
				type: 'bool',
			},
		],
		payable: false,
		stateMutability: 'nonpayable',
		type: 'function',
	},
	{
		constant: false,
		inputs: [
			{
				name: 'account',
				type: 'address',
			},
			{
				name: 'amount',
				type: 'uint256',
			},
		],
		name: 'mint',
		outputs: [
			{
				name: '',
				type: 'bool',
			},
		],
		payable: false,
		stateMutability: 'nonpayable',
		type: 'function',
	},
	{
		constant: true,
		inputs: [
			{
				name: 'account',
				type: 'address',
			},
		],
		name: 'balanceOf',
		outputs: [
			{
				name: '',
				type: 'uint256',
			},
		],
		payable: false,
		stateMutability: 'view',
		type: 'function',
	},
	{
		constant: false,
		inputs: [],
		name: 'renounceOwnership',
		outputs: [],
		payable: false,
		stateMutability: 'nonpayable',
		type: 'function',
	},
	{
		constant: true,
		inputs: [],
		name: 'owner',
		outputs: [
			{
				name: '',
				type: 'address',
			},
		],
		payable: false,
		stateMutability: 'view',
		type: 'function',
	},
	{
		constant: true,
		inputs: [],
		name: 'isOwner',
		outputs: [
			{
				name: '',
				type: 'bool',
			},
		],
		payable: false,
		stateMutability: 'view',
		type: 'function',
	},
	{
		constant: true,
		inputs: [],
		name: 'symbol',
		outputs: [
			{
				name: '',
				type: 'string',
			},
		],
		payable: false,
		stateMutability: 'view',
		type: 'function',
	},
	{
		constant: false,
		inputs: [
			{
				name: 'account',
				type: 'address',
			},
		],
		name: 'addMinter',
		outputs: [],
		payable: false,
		stateMutability: 'nonpayable',
		type: 'function',
	},
	{
		constant: false,
		inputs: [],
		name: 'renounceMinter',
		outputs: [],
		payable: false,
		stateMutability: 'nonpayable',
		type: 'function',
	},
	{
		constant: false,
		inputs: [
			{
				name: 'who',
				type: 'address',
			},
			{
				name: 'value',
				type: 'uint256',
			},
		],
		name: 'burn',
		outputs: [],
		payable: false,
		stateMutability: 'nonpayable',
		type: 'function',
	},
	{
		constant: false,
		inputs: [
			{
				name: 'spender',
				type: 'address',
			},
			{
				name: 'subtractedValue',
				type: 'uint256',
			},
		],
		name: 'decreaseAllowance',
		outputs: [
			{
				name: '',
				type: 'bool',
			},
		],
		payable: false,
		stateMutability: 'nonpayable',
		type: 'function',
	},
	{
		constant: false,
		inputs: [
			{
				name: 'recipient',
				type: 'address',
			},
			{
				name: 'amount',
				type: 'uint256',
			},
		],
		name: 'transfer',
		outputs: [
			{
				name: '',
				type: 'bool',
			},
		],
		payable: false,
		stateMutability: 'nonpayable',
		type: 'function',
	},
	{
		constant: true,
		inputs: [
			{
				name: 'account',
				type: 'address',
			},
		],
		name: 'isMinter',
		outputs: [
			{
				name: '',
				type: 'bool',
			},
		],
		payable: false,
		stateMutability: 'view',
		type: 'function',
	},
	{
		constant: true,
		inputs: [
			{
				name: 'owner',
				type: 'address',
			},
			{
				name: 'spender',
				type: 'address',
			},
		],
		name: 'allowance',
		outputs: [
			{
				name: '',
				type: 'uint256',
			},
		],
		payable: false,
		stateMutability: 'view',
		type: 'function',
	},
	{
		constant: false,
		inputs: [
			{
				name: 'newOwner',
				type: 'address',
			},
		],
		name: 'transferOwnership',
		outputs: [],
		payable: false,
		stateMutability: 'nonpayable',
		type: 'function',
	},
	{
		inputs: [],
		payable: false,
		stateMutability: 'nonpayable',
		type: 'constructor',
	},
	{
		payable: false,
		stateMutability: 'nonpayable',
		type: 'fallback',
	},
	{
		anonymous: false,
		inputs: [
			{
				indexed: true,
				name: 'account',
				type: 'address',
			},
		],
		name: 'MinterAdded',
		type: 'event',
	},
	{
		anonymous: false,
		inputs: [
			{
				indexed: true,
				name: 'account',
				type: 'address',
			},
		],
		name: 'MinterRemoved',
		type: 'event',
	},
	{
		anonymous: false,
		inputs: [
			{
				indexed: true,
				name: 'from',
				type: 'address',
			},
			{
				indexed: true,
				name: 'to',
				type: 'address',
			},
			{
				indexed: false,
				name: 'value',
				type: 'uint256',
			},
		],
		name: 'Transfer',
		type: 'event',
	},
	{
		anonymous: false,
		inputs: [
			{
				indexed: true,
				name: 'owner',
				type: 'address',
			},
			{
				indexed: true,
				name: 'spender',
				type: 'address',
			},
			{
				indexed: false,
				name: 'value',
				type: 'uint256',
			},
		],
		name: 'Approval',
		type: 'event',
	},
	{
		anonymous: false,
		inputs: [
			{
				indexed: true,
				name: 'previousOwner',
				type: 'address',
			},
			{
				indexed: true,
				name: 'newOwner',
				type: 'address',
			},
		],
		name: 'OwnershipTransferred',
		type: 'event',
	},
];

export const ABI_DCA = [
	{
		inputs: [
			{
				internalType: 'address',
				name: 'docTokenAddress',
				type: 'address',
			},
			{
				internalType: 'address',
				name: 'mocProxyAddress',
				type: 'address',
			},
		],
		stateMutability: 'nonpayable',
		type: 'constructor',
	},
	{
		inputs: [
			{
				internalType: 'address',
				name: 'owner',
				type: 'address',
			},
		],
		name: 'OwnableInvalidOwner',
		type: 'error',
	},
	{
		inputs: [
			{
				internalType: 'address',
				name: 'account',
				type: 'address',
			},
		],
		name: 'OwnableUnauthorizedAccount',
		type: 'error',
	},
	{
		inputs: [],
		name: 'RbtcDca__CannotBuyIfPurchasePeriodHasNotElapsed',
		type: 'error',
	},
	{
		inputs: [],
		name: 'RbtcDca__CannotWithdrawRbtcBeforeBuying',
		type: 'error',
	},
	{
		inputs: [],
		name: 'RbtcDca__DepositAmountMustBeGreaterThanZero',
		type: 'error',
	},
	{
		inputs: [],
		name: 'RbtcDca__DocDepositFailed',
		type: 'error',
	},
	{
		inputs: [],
		name: 'RbtcDca__DocWithdrawalAmountExceedsBalance',
		type: 'error',
	},
	{
		inputs: [],
		name: 'RbtcDca__DocWithdrawalAmountMustBeGreaterThanZero',
		type: 'error',
	},
	{
		inputs: [],
		name: 'RbtcDca__DocWithdrawalFailed',
		type: 'error',
	},
	{
		inputs: [],
		name: 'RbtcDca__NotEnoughDocAllowanceForDcaContract',
		type: 'error',
	},
	{
		inputs: [],
		name: 'RbtcDca__OnlyMocProxyContractCanSendRbtcToDcaContract',
		type: 'error',
	},
	{
		inputs: [],
		name: 'RbtcDca__PurchaseAmountMustBeGreaterThanZero',
		type: 'error',
	},
	{
		inputs: [],
		name: 'RbtcDca__PurchaseAmountMustBeLowerThanHalfOfBalance',
		type: 'error',
	},
	{
		inputs: [],
		name: 'RbtcDca__PurchasePeriodMustBeGreaterThanZero',
		type: 'error',
	},
	{
		inputs: [],
		name: 'RbtcDca__RedeemDocRequestFailed',
		type: 'error',
	},
	{
		inputs: [],
		name: 'RbtcDca__RedeemFreeDocFailed',
		type: 'error',
	},
	{
		inputs: [],
		name: 'RbtcDca__rBtcWithdrawalFailed',
		type: 'error',
	},
	{
		anonymous: false,
		inputs: [
			{
				indexed: true,
				internalType: 'address',
				name: 'user',
				type: 'address',
			},
			{
				indexed: false,
				internalType: 'uint256',
				name: 'amount',
				type: 'uint256',
			},
		],
		name: 'DocDeposited',
		type: 'event',
	},
	{
		anonymous: false,
		inputs: [
			{
				indexed: true,
				internalType: 'address',
				name: 'user',
				type: 'address',
			},
			{
				indexed: false,
				internalType: 'uint256',
				name: 'amount',
				type: 'uint256',
			},
		],
		name: 'DocWithdrawn',
		type: 'event',
	},
	{
		anonymous: false,
		inputs: [
			{
				indexed: true,
				internalType: 'address',
				name: 'previousOwner',
				type: 'address',
			},
			{
				indexed: true,
				internalType: 'address',
				name: 'newOwner',
				type: 'address',
			},
		],
		name: 'OwnershipTransferred',
		type: 'event',
	},
	{
		anonymous: false,
		inputs: [
			{
				indexed: true,
				internalType: 'address',
				name: 'user',
				type: 'address',
			},
			{
				indexed: false,
				internalType: 'uint256',
				name: 'purchaseAmount',
				type: 'uint256',
			},
		],
		name: 'PurchaseAmountSet',
		type: 'event',
	},
	{
		anonymous: false,
		inputs: [
			{
				indexed: true,
				internalType: 'address',
				name: 'user',
				type: 'address',
			},
			{
				indexed: false,
				internalType: 'uint256',
				name: 'purchasePeriod',
				type: 'uint256',
			},
		],
		name: 'PurchasePeriodSet',
		type: 'event',
	},
	{
		anonymous: false,
		inputs: [
			{
				indexed: true,
				internalType: 'address',
				name: 'user',
				type: 'address',
			},
			{
				indexed: false,
				internalType: 'uint256',
				name: 'docAmount',
				type: 'uint256',
			},
			{
				indexed: false,
				internalType: 'uint256',
				name: 'rbtcAmount',
				type: 'uint256',
			},
		],
		name: 'RbtcBought',
		type: 'event',
	},
	{
		anonymous: false,
		inputs: [
			{
				indexed: true,
				internalType: 'address',
				name: 'user',
				type: 'address',
			},
			{
				indexed: false,
				internalType: 'uint256',
				name: 'depositAmount',
				type: 'uint256',
			},
			{
				indexed: false,
				internalType: 'uint256',
				name: 'purchaseAmount',
				type: 'uint256',
			},
			{
				indexed: false,
				internalType: 'uint256',
				name: 'purchasePeriod',
				type: 'uint256',
			},
		],
		name: 'newDcaScheduleCreated',
		type: 'event',
	},
	{
		anonymous: false,
		inputs: [
			{
				indexed: true,
				internalType: 'address',
				name: 'user',
				type: 'address',
			},
			{
				indexed: false,
				internalType: 'uint256',
				name: 'rbtcAmount',
				type: 'uint256',
			},
		],
		name: 'rBtcWithdrawn',
		type: 'event',
	},
	{
		inputs: [
			{
				internalType: 'address',
				name: 'buyer',
				type: 'address',
			},
		],
		name: 'buyRbtc',
		outputs: [],
		stateMutability: 'nonpayable',
		type: 'function',
	},
	{
		inputs: [
			{
				internalType: 'uint256',
				name: 'depositAmount',
				type: 'uint256',
			},
			{
				internalType: 'uint256',
				name: 'purchaseAmount',
				type: 'uint256',
			},
			{
				internalType: 'uint256',
				name: 'purchasePeriod',
				type: 'uint256',
			},
		],
		name: 'createDcaSchedule',
		outputs: [],
		stateMutability: 'nonpayable',
		type: 'function',
	},
	{
		inputs: [
			{
				internalType: 'uint256',
				name: 'depositAmount',
				type: 'uint256',
			},
		],
		name: 'depositDOC',
		outputs: [],
		stateMutability: 'nonpayable',
		type: 'function',
	},
	{
		inputs: [],
		name: 'getDocBalance',
		outputs: [
			{
				internalType: 'uint256',
				name: '',
				type: 'uint256',
			},
		],
		stateMutability: 'view',
		type: 'function',
	},
	{
		inputs: [],
		name: 'getMyDcaDetails',
		outputs: [
			{
				components: [
					{
						internalType: 'uint256',
						name: 'docBalance',
						type: 'uint256',
					},
					{
						internalType: 'uint256',
						name: 'docPurchaseAmount',
						type: 'uint256',
					},
					{
						internalType: 'uint256',
						name: 'purchasePeriod',
						type: 'uint256',
					},
					{
						internalType: 'uint256',
						name: 'lastPurchaseTimestamp',
						type: 'uint256',
					},
					{
						internalType: 'uint256',
						name: 'rbtcBalance',
						type: 'uint256',
					},
				],
				internalType: 'struct RbtcDca.DcaDetails',
				name: '',
				type: 'tuple',
			},
		],
		stateMutability: 'view',
		type: 'function',
	},
	{
		inputs: [],
		name: 'getPurchaseAmount',
		outputs: [
			{
				internalType: 'uint256',
				name: '',
				type: 'uint256',
			},
		],
		stateMutability: 'view',
		type: 'function',
	},
	{
		inputs: [],
		name: 'getPurchasePeriod',
		outputs: [
			{
				internalType: 'uint256',
				name: '',
				type: 'uint256',
			},
		],
		stateMutability: 'view',
		type: 'function',
	},
	{
		inputs: [],
		name: 'getRbtcBalance',
		outputs: [
			{
				internalType: 'uint256',
				name: '',
				type: 'uint256',
			},
		],
		stateMutability: 'view',
		type: 'function',
	},
	{
		inputs: [],
		name: 'getTotalNumberOfDeposits',
		outputs: [
			{
				internalType: 'uint256',
				name: '',
				type: 'uint256',
			},
		],
		stateMutability: 'view',
		type: 'function',
	},
	{
		inputs: [],
		name: 'getUsers',
		outputs: [
			{
				internalType: 'address[]',
				name: '',
				type: 'address[]',
			},
		],
		stateMutability: 'view',
		type: 'function',
	},
	{
		inputs: [],
		name: 'owner',
		outputs: [
			{
				internalType: 'address',
				name: '',
				type: 'address',
			},
		],
		stateMutability: 'view',
		type: 'function',
	},
	{
		inputs: [
			{
				internalType: 'address',
				name: 'user',
				type: 'address',
			},
		],
		name: 'ownerGetUsersDcaDetails',
		outputs: [
			{
				components: [
					{
						internalType: 'uint256',
						name: 'docBalance',
						type: 'uint256',
					},
					{
						internalType: 'uint256',
						name: 'docPurchaseAmount',
						type: 'uint256',
					},
					{
						internalType: 'uint256',
						name: 'purchasePeriod',
						type: 'uint256',
					},
					{
						internalType: 'uint256',
						name: 'lastPurchaseTimestamp',
						type: 'uint256',
					},
					{
						internalType: 'uint256',
						name: 'rbtcBalance',
						type: 'uint256',
					},
				],
				internalType: 'struct RbtcDca.DcaDetails',
				name: '',
				type: 'tuple',
			},
		],
		stateMutability: 'view',
		type: 'function',
	},
	{
		inputs: [],
		name: 'renounceOwnership',
		outputs: [],
		stateMutability: 'nonpayable',
		type: 'function',
	},
	{
		inputs: [
			{
				internalType: 'uint256',
				name: 'purchaseAmount',
				type: 'uint256',
			},
		],
		name: 'setPurchaseAmount',
		outputs: [],
		stateMutability: 'nonpayable',
		type: 'function',
	},
	{
		inputs: [
			{
				internalType: 'uint256',
				name: 'purchasePeriod',
				type: 'uint256',
			},
		],
		name: 'setPurchasePeriod',
		outputs: [],
		stateMutability: 'nonpayable',
		type: 'function',
	},
	{
		inputs: [
			{
				internalType: 'address',
				name: 'newOwner',
				type: 'address',
			},
		],
		name: 'transferOwnership',
		outputs: [],
		stateMutability: 'nonpayable',
		type: 'function',
	},
	{
		inputs: [],
		name: 'withdrawAccumulatedRbtc',
		outputs: [],
		stateMutability: 'nonpayable',
		type: 'function',
	},
	{
		inputs: [
			{
				internalType: 'uint256',
				name: 'withdrawalAmount',
				type: 'uint256',
			},
		],
		name: 'withdrawDOC',
		outputs: [],
		stateMutability: 'nonpayable',
		type: 'function',
	},
	{
		stateMutability: 'payable',
		type: 'receive',
	},
];
