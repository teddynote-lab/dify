'use client'
import {
  RiSunLine,
} from '@remixicon/react'
import { useTheme } from 'next-themes'

export type Theme = 'light' | 'dark' | 'system'

export default function ThemeSwitcher() {
  const { theme, setTheme } = useTheme()

  const handleThemeChange = (newTheme: Theme) => {
    setTheme(newTheme)
  }

  return (
    <div className='flex items-center rounded-[10px] bg-components-segmented-control-bg-normal p-0.5'>
      <div
        className='rounded-lg bg-components-segmented-control-item-active-bg px-2 py-1 text-text-accent-light-mode-only shadow-sm'
      >
        <div className='p-0.5'>
          <RiSunLine className='h-4 w-4' />
        </div>
      </div>
    </div>
  )
}
