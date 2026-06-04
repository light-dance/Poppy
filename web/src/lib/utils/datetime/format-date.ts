const DAY_MS = 24 * 60 * 60 * 1_000

export type FormatDateOptions = {
	dayOrdinal?: boolean
	weekday?: boolean
	year?: 'auto' | 'always'
}

export type FormattedDate = {
	date: {
		long: string
		short: string
		relative: string
	}
	time: {
		short: string
		long: string
	}
}

/**
 * Format a Date into opinionated long, short, and relative date labels plus short/long time labels.
 *
 * @param date - The Date to render.
 * @param options - Formatting behavior for ordinal day suffixes, weekday prefixing, and year policy.
 * @returns A bundle of date variants (`long`, `short`, `relative`) and time variants (`short`, `long`).
 * @example
 * ```ts
 * formatDate(new Date('2025-02-07T13:32:00-05:00'))
 * // => {
 * //   date: { long: 'Feb 7th', short: 'Feb 7th', relative: 'Feb 7th' },
 * //   time: { short: '1PM', long: '1:32PM' }
 * // }
 * ```
 * @example
 * ```ts
 * formatDate(new Date('2025-02-03T13:32:00-05:00'), { weekday: true, year: 'always' })
 * // => {
 * //   date: { long: 'Mon, Feb 3rd, 2025', short: 'Feb 3rd, 2025', relative: 'Monday' },
 * //   time: { short: '1PM', long: '1:32PM' }
 * // }
 * ```
 */
export function formatDate(date: Date, options: FormatDateOptions = {}) {
	assertValidDate(date)

	const { dayOrdinal = true, weekday = false, year = 'auto' } = options
	const now = new Date()
	const localDayDiff = getLocalCalendarDayDiff(date, now)
	const includeYear = year === 'always' || date.getFullYear() !== now.getFullYear()
	const isToday = localDayDiff === 0
	const isYesterday = localDayDiff === -1
	const isWithinLastWeek = localDayDiff <= 0 && localDayDiff > -7

	const shortDate = formatMonthDay(date, {
		includeYear,
		includeWeekdayPrefix: false,
		dayOrdinal
	})
	const longDate = formatMonthDay(date, {
		includeYear,
		includeWeekdayPrefix: weekday,
		dayOrdinal
	})
	const relativeDate = formatRelativeDate({
		date,
		fallback: shortDate,
		isToday,
		isYesterday,
		isWithinLastWeek
	})

	return {
		date: {
			long: longDate,
			short: shortDate,
			relative: relativeDate
		},
		time: {
			short: formatTime(date, 'short'),
			long: formatTime(date, 'long')
		}
	}
}

function formatRelativeDate({
	date,
	fallback,
	isToday,
	isYesterday,
	isWithinLastWeek
}: {
	date: Date
	fallback: string
	isToday: boolean
	isYesterday: boolean
	isWithinLastWeek: boolean
}) {
	if (isToday) return 'Today'
	if (isYesterday) return 'Yesterday'
	if (isWithinLastWeek) return formatWeekday(date, 'long')

	return fallback
}

/**
 * Format a Date as local time text.
 *
 * @param date - The Date to format.
 * @param style - Whether to render hour-only (`short`) or hour+minute (`long`).
 * @returns Time label in en-US style with compact AM/PM suffix.
 * @example
 * ```ts
 * formatTime(new Date('2026-02-15T13:32:00'), 'long')
 * // => "1:32PM"
 * ```
 */
function formatTime(date: Date, style: 'short' | 'long') {
	const formatted = new Intl.DateTimeFormat('en-US', {
		hour: 'numeric',
		minute: style === 'long' ? '2-digit' : undefined,
		hour12: true
	}).format(date)

	return formatted.replace(/\s/g, '')
}

/**
 * Format month/day with optional ordinal suffix, weekday prefix, and year.
 *
 * @param date - Date to format.
 * @param options - Controls inclusion of year, short weekday prefix, and ordinal day suffix.
 * @returns Formatted date label.
 * @example
 * ```ts
 * formatMonthDay(new Date('2025-02-07T00:00:00'), { includeYear: true, includeWeekdayPrefix: true, dayOrdinal: true })
 * // => "Fri, Feb 7th, 2025"
 * ```
 */
function formatMonthDay(
	date: Date,
	options: { includeYear: boolean; includeWeekdayPrefix: boolean; dayOrdinal: boolean }
) {
	const month = new Intl.DateTimeFormat('en-US', { month: 'short' }).format(date)
	const day = date.getDate()
	const year = date.getFullYear()
	const dayText = options.dayOrdinal ? `${day}${toOrdinalSuffix(day)}` : String(day)
	let datePart = `${month} ${dayText}`

	if (options.includeYear) {
		datePart = `${datePart}, ${year}`
	}

	if (options.includeWeekdayPrefix) {
		return `${formatWeekday(date, 'short')}, ${datePart}`
	}

	return datePart
}

/**
 * Format weekday text in en-US.
 *
 * @param date - Date to format.
 * @param style - Long (`Tuesday`) or short (`Tue`) weekday.
 * @returns Weekday label.
 * @example
 * ```ts
 * formatWeekday(new Date('2026-02-17T12:00:00'), 'long')
 * // => "Tuesday"
 * ```
 */
function formatWeekday(date: Date, style: 'long' | 'short') {
	return new Intl.DateTimeFormat('en-US', { weekday: style }).format(date)
}

/**
 * Compute local calendar-day difference between target and base dates.
 *
 * @param target - Target date.
 * @param base - Base date.
 * @returns Day difference where negative values mean target is earlier than base.
 * @example
 * ```ts
 * getLocalCalendarDayDiff(new Date('2026-02-14T23:00:00'), new Date('2026-02-15T01:00:00'))
 * // => -1
 * ```
 */
function getLocalCalendarDayDiff(target: Date, base: Date) {
	const targetIndex = Math.floor(
		Date.UTC(target.getFullYear(), target.getMonth(), target.getDate()) / DAY_MS
	)
	const baseIndex = Math.floor(
		Date.UTC(base.getFullYear(), base.getMonth(), base.getDate()) / DAY_MS
	)
	return targetIndex - baseIndex
}

/**
 * Convert a day-of-month number to an English ordinal suffix.
 *
 * @param day - Day number within the month.
 * @returns Ordinal suffix (`st`, `nd`, `rd`, `th`).
 * @example
 * ```ts
 * toOrdinalSuffix(7)
 * // => "th"
 * ```
 */
function toOrdinalSuffix(day: number) {
	const mod100 = day % 100
	if (mod100 >= 11 && mod100 <= 13) return 'th'
	switch (day % 10) {
		case 1:
			return 'st'
		case 2:
			return 'nd'
		case 3:
			return 'rd'
		default:
			return 'th'
	}
}

/**
 * Guard against `Invalid Date` values before formatting.
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
		throw new Error('Invalid Date passed to datetime formatter')
	}
}
