'use client'
import { useTranslation } from 'react-i18next'
import { useCallback } from 'react'

import { useRouter } from 'next/navigation'
import { debounce } from 'lodash-es'
import { useAppContext } from '@/context/app-context'
import { useStore as useAppStore } from '@/app/components/app/store'
import type { AppIconType } from '@/types/app'

export type NavItem = {
  id: string
  name: string
  link: string
  icon_type: AppIconType | null
  icon: string
  icon_background: string
  icon_url: string | null
  mode?: string
}
export type INavSelectorProps = {
  navs: NavItem[]
  curNav?: Omit<NavItem, 'link'>
  createText: string
  isApp?: boolean
  onCreate: (state: string) => void
  onLoadmore?: () => void
}

const NavSelector = ({ curNav, navs, createText, isApp, onCreate, onLoadmore }: INavSelectorProps) => {
  const { t } = useTranslation()
  const router = useRouter()
  const { isCurrentWorkspaceEditor } = useAppContext()
  const setAppDetail = useAppStore(state => state.setAppDetail)

  const handleScroll = useCallback(debounce((e) => {
    if (typeof onLoadmore === 'function') {
      const { clientHeight, scrollHeight, scrollTop } = e.target

      if (clientHeight + scrollTop > scrollHeight - 50)
        onLoadmore()
    }
  }, 50), [])

  return (
    <span className='inline-flex h-7 items-center justify-center rounded-[10px] bg-components-main-nav-nav-button-bg-active px-2 text-[14px] font-semibold text-components-main-nav-nav-button-text-active'>
      <div className='max-w-[157px] truncate' title={curNav?.name}>{curNav?.name}</div>
    </span>
  )
}

export default NavSelector
