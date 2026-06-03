const SECOND_MS = 1_000
const MINUTE_MS = 60 * SECOND_MS
const HOUR_MS = 60 * MINUTE_MS
const DAY_MS = 24 * HOUR_MS
const WEEK_MS = 7 * DAY_MS
const MONTH_MS = 30 * DAY_MS
const YEAR_MS = 365 * DAY_MS

export type DurationUnit = 'year' | 'month' | 'week' | 'day' | 'hour' | 'minute' | 'second'

export type FormatDurationOptions = {
	maxUnit?: DurationUnit
	monthThresholdWeeks?: number
	style?: 'short' | 'full'
}

export type DurationParts = {
	years: number | null
	months: number | null
	weeks: number | null
	days: number | null
	hours: number | null
	minutes: number | null
	seconds: number | null
}

export type FormattedDuration = {
	short: string
	largest: { unit: DurationUnit; value: number }
	parts: DurationParts
	ms: number
}

type UnitValues = Record<DurationUnit, number>

const UNIT_ORDER: DurationUnit[] = ['year', 'month', 'week', 'day', 'hour', 'minute', 'second']
const UNIT_MS: UnitValues = {
	year: YEAR_MS,
	month: MONTH_MS,
	week: WEEK_MS,
	day: DAY_MS,
	hour: HOUR_MS,
	minute: MINUTE_MS,
	second: SECOND_MS
}

const UNIT_LABELS: Record<
	'short' | 'full',
	Record<DurationUnit, [singular: string, plural: string]>
> = {
	short: {
		year: ['y', 'y'],
		month: ['mo', 'mo'],
		week: ['w', 'w'],
		day: ['d', 'd'],
		hour: ['h', 'h'],
		minute: ['m', 'm'],
		second: ['s', 's']
	},
	full: {
		year: ['year', 'years'],
		month: ['month', 'months'],
		week: ['week', 'weeks'],
		day: ['day', 'days'],
		hour: ['hour', 'hours'],
		minute: ['minute', 'minutes'],
		second: ['second', 'seconds']
	}
}

/**
 * Format a duration from milliseconds into a short label and decomposed parts.
 *
 * For millisecond-based durations, month and year are treated as fixed-length
 * units (30-day month, 365-day year).
 *
 * @param milliseconds - Duration in milliseconds.
 * @param options - Behavior for maximum display unit, month thresholding, and label style.
 * @returns Duration metadata including `short`, `largest`, `parts`, and normalized `ms`.
 * @example
 * ```ts
 * formatDuration(5 * 60 * 1000)
 * // => { short: '5m', ... }
 * ```
 * @example
 * ```ts
 * formatDuration(365 * 24 * 60 * 60 * 1000, { maxUnit: 'day' })
 * // => { short: '365 days', ... }
 * ```
 */
export function formatDuration(milliseconds: number, options: FormatDurationOptions = {}) {
	const absMs = Math.abs(milliseconds)
	const maxUnit = options.maxUnit ?? 'year'
	const monthThresholdWeeks = options.monthThresholdWeeks ?? 6
	const style = options.style ?? 'short'
	const allowCalendarMonths = absMs > monthThresholdWeeks * WEEK_MS
	const units = getCandidateUnits(maxUnit, allowCalendarMonths)
	const values = decomposeMilliseconds(absMs, units)

	return buildDurationResult(values, units, absMs, style)
}

/**
 * Format a duration between two dates into a short label and decomposed parts.
 *
 * If only `from` is provided, `to` defaults to the current time. Month and year
 * decomposition uses calendar boundaries (clamped month addition) rather than fixed ms.
 *
 * @param from - Start date.
 * @param to - End date (defaults to now).
 * @param options - Behavior for maximum display unit, month thresholding, and label style.
 * @returns Duration metadata including `short`, `largest`, `parts`, and normalized `ms`.
 * @example
 * ```ts
 * formatDateDuration(new Date(Date.now() - 8 * 24 * 60 * 60 * 1000))
 * // => { short: '1w', ... }
 * ```
 */
export function formatDateDuration(
	from: Date,
	to: Date = new Date(),
	options: FormatDurationOptions = {}
) {
	assertValidDate(from)
	assertValidDate(to)

	const [start, end] = from.getTime() <= to.getTime() ? [from, to] : [to, from]
	const absMs = end.getTime() - start.getTime()
	const maxUnit = options.maxUnit ?? 'year'
	const monthThresholdWeeks = options.monthThresholdWeeks ?? 6
	const style = options.style ?? 'short'
	const allowCalendarMonths = absMs > monthThresholdWeeks * WEEK_MS
	const units = getCandidateUnits(maxUnit, allowCalendarMonths)
	const values = decomposeDates(start, end, units)

	return buildDurationResult(values, units, absMs, style)
}

/**
 * Build final formatted duration output from computed unit values.
 *
 * @param values - Unit values from decomposition.
 * @param units - Allowed units in descending order.
 * @param absMs - Absolute duration in milliseconds.
 * @param style - Label style for the short string.
 * @returns Final duration result object.
 * @example
 * ```ts
 * buildDurationResult({ year: 0, month: 0, week: 1, day: 0, hour: 0, minute: 0, second: 0 }, ['week', 'day'], 604800000, 'short')
 * ```
 */
function buildDurationResult(
	values: UnitValues,
	units: DurationUnit[],
	absMs: number,
	style: 'short' | 'full'
) {
	const largestUnit = units.find((unit) => values[unit] > 0) ?? units[units.length - 1] ?? 'second'
	const largestValue = values[largestUnit]
	const largestLabel = UNIT_LABELS[style][largestUnit][largestValue === 1 ? 0 : 1]
	const separator = style === 'short' ? '' : ' '

	return {
		short: `${largestValue}${separator}${largestLabel}`,
		largest: {
			unit: largestUnit,
			value: largestValue
		},
		parts: {
			years: values.year > 0 ? values.year : null,
			months: values.month > 0 ? values.month : null,
			weeks: values.week > 0 ? values.week : null,
			days: values.day > 0 ? values.day : null,
			hours: values.hour > 0 ? values.hour : null,
			minutes: values.minute > 0 ? values.minute : null,
			seconds: values.second > 0 ? values.second : null
		},
		ms: absMs
	}
}

/**
 * Decompose milliseconds into unit values using fixed unit lengths.
 *
 * @param absMs - Absolute duration in milliseconds.
 * @param units - Allowed units in descending order.
 * @returns Unit values for each duration unit.
 * @example
 * ```ts
 * decomposeMilliseconds(49 * 60 * 60 * 1000, ['day', 'hour', 'minute', 'second'])
 * // => { day: 2, hour: 1, ... }
 * ```
 */
function decomposeMilliseconds(absMs: number, units: DurationUnit[]) {
	let remainder = absMs
	const values = createEmptyValues()

	for (const unit of units) {
		const unitMs = UNIT_MS[unit]
		const value = Math.floor(remainder / unitMs)
		values[unit] = value
		remainder -= value * unitMs
	}

	// Ensure at least one unit value for tiny durations.
	if (units.includes('second') && allZero(values, units)) {
		values.second = 1
	}

	return values
}

/**
 * Decompose a date range into unit values using calendar-aware month/year boundaries.
 *
 * @param start - Earlier date.
 * @param end - Later date.
 * @param units - Allowed units in descending order.
 * @returns Unit values for each duration unit.
 * @example
 * ```ts
 * decomposeDates(new Date('2026-01-31'), new Date('2026-03-02'), ['month', 'week', 'day'])
 * ```
 */
function decomposeDates(start: Date, end: Date, units: DurationUnit[]) {
	const values = createEmptyValues()
	let cursor = new Date(start.getTime())

	if (units.includes('year')) {
		const years = wholeYearsBetween(cursor, end)
		values.year = years
		cursor = addMonthsClamped(cursor, years * 12)
	}

	if (units.includes('month')) {
		const months = wholeMonthsBetween(cursor, end)
		values.month = months
		cursor = addMonthsClamped(cursor, months)
	}

	const remainingMs = Math.max(0, end.getTime() - cursor.getTime())
	const smallerUnits = units.filter((unit) => unit !== 'year' && unit !== 'month')
	const smallerValues = decomposeMilliseconds(remainingMs, smallerUnits)

	for (const unit of smallerUnits) {
		values[unit] = smallerValues[unit]
	}

	if (units.includes('second') && allZero(values, units)) {
		values.second = 1
	}

	return values
}

/**
 * Determine whole years elapsed between two dates.
 *
 * @param start - Start date.
 * @param end - End date.
 * @returns Whole-year count.
 * @example
 * ```ts
 * wholeYearsBetween(new Date('2020-02-29'), new Date('2021-02-28'))
 * // => 0
 * ```
 */
function wholeYearsBetween(start: Date, end: Date) {
	let years = end.getFullYear() - start.getFullYear()
	if (years <= 0) return 0

	while (years > 0 && addMonthsClamped(start, years * 12).getTime() > end.getTime()) {
		years--
	}

	return years
}

/**
 * Determine whole months elapsed between two dates.
 *
 * @param start - Start date.
 * @param end - End date.
 * @returns Whole-month count.
 * @example
 * ```ts
 * wholeMonthsBetween(new Date('2026-01-31'), new Date('2026-03-01'))
 * // => 1
 * ```
 */
function wholeMonthsBetween(start: Date, end: Date) {
	let months = (end.getFullYear() - start.getFullYear()) * 12 + (end.getMonth() - start.getMonth())
	if (months <= 0) return 0

	while (months > 0 && addMonthsClamped(start, months).getTime() > end.getTime()) {
		months--
	}

	return months
}

/**
 * Add months while clamping the day to the target month's maximum day.
 *
 * @param date - Base date.
 * @param months - Number of months to add.
 * @returns Adjusted date.
 * @example
 * ```ts
 * addMonthsClamped(new Date('2026-01-31T10:00:00'), 1)
 * // => 2026-02-28T10:00:00 (local)
 * ```
 */
function addMonthsClamped(date: Date, months: number) {
	const year = date.getFullYear()
	const month = date.getMonth() + months
	const day = date.getDate()

	const targetYear = year + Math.floor(month / 12)
	const targetMonth = ((month % 12) + 12) % 12
	const maxDay = new Date(targetYear, targetMonth + 1, 0).getDate()
	const clampedDay = Math.min(day, maxDay)

	return new Date(
		targetYear,
		targetMonth,
		clampedDay,
		date.getHours(),
		date.getMinutes(),
		date.getSeconds(),
		date.getMilliseconds()
	)
}

/**
 * Build ordered unit candidates constrained by max unit and month-threshold rule.
 *
 * @param maxUnit - Largest permitted unit.
 * @param allowCalendarMonths - Whether year/month units are allowed.
 * @returns Ordered unit list from largest to smallest.
 * @example
 * ```ts
 * getCandidateUnits('day', true)
 * // => ['day', 'hour', 'minute', 'second']
 * ```
 */
function getCandidateUnits(maxUnit: DurationUnit, allowCalendarMonths: boolean) {
	const startIndex = UNIT_ORDER.indexOf(maxUnit)
	const units = UNIT_ORDER.slice(startIndex === -1 ? 0 : startIndex)

	if (allowCalendarMonths) {
		return units
	}

	return units.filter((unit) => unit !== 'year' && unit !== 'month')
}

/**
 * Create a zero-initialized unit-value map.
 *
 * @returns Empty unit values.
 * @example
 * ```ts
 * createEmptyValues()
 * // => { year: 0, month: 0, ... }
 * ```
 */
function createEmptyValues() {
	return {
		year: 0,
		month: 0,
		week: 0,
		day: 0,
		hour: 0,
		minute: 0,
		second: 0
	}
}

/**
 * Check whether all candidate units are zero.
 *
 * @param values - Unit values.
 * @param units - Units to inspect.
 * @returns True if all provided units have value 0.
 * @example
 * ```ts
 * allZero({ year: 0, month: 0, week: 0, day: 0, hour: 0, minute: 0, second: 0 }, ['week', 'day'])
 * // => true
 * ```
 */
function allZero(values: UnitValues, units: DurationUnit[]) {
	return units.every((unit) => values[unit] === 0)
}

/**
 * Validate that a Date object is valid.
 *
 * @param date - Date to validate.
 * @returns Nothing. Throws if the date is invalid.
 * @example
 * ```ts
 * assertValidDate(new Date('invalid'))
 * // throws Error
 * ```
 */
function assertValidDate(date: Date) {
	if (Number.isNaN(date.getTime())) {
		throw new Error('Invalid Date passed to duration formatter')
	}
}
