'use client'
import type { AppIconType } from '@/types/app'

export type NavItem = {
  id: string
  name: string
  link: string
  icon_type: AppIconType | null
  icon: string
  icon_background: string | null
  icon_url: string | null
  mode?: string
}
export type INavSelectorProps = {
  navigationItems: NavItem[]
  curNav?: Omit<NavItem, 'link'>
  createText: string
  isApp?: boolean
  onCreate: (state: string) => void
  onLoadMore?: () => void
}

const NavSelector = ({ curNav }: INavSelectorProps) => {
  return (
    <span className='inline-flex h-7 items-center justify-center rounded-[10px] bg-components-main-nav-nav-button-bg-active px-2 text-[14px] font-semibold text-components-main-nav-nav-button-text-active'>
      <div className='max-w-[157px] truncate' title={curNav?.name}>{curNav?.name}</div>
    </span>
  )
}

export default NavSelector
