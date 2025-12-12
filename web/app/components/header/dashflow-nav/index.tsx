'use client'

import Link from 'next/link'
import {
  RiLinksLine,
} from '@remixicon/react'
import classNames from '@/utils/classnames'

type DashFlowNavProps = {
  className?: string
}

const DashFlowNav = ({
  className,
}: DashFlowNavProps) => {
  const brandName = process.env.NEXT_PUBLIC_BRAND_NAME || 'DashFlow'
  const brandUrl = process.env.NEXT_PUBLIC_BRAND_URL || 'https://dashflow.studio/'

  return (
    <Link
      href={brandUrl}
      target="_blank"
      rel="noopener noreferrer"
      className={classNames(
        className,
        'group',
        'text-components-main-nav-nav-button-text hover:bg-components-main-nav-nav-button-bg-hover',
      )}
    >
      <RiLinksLine className='h-4 w-4' />
      <div className='ml-2 max-[1024px]:hidden'>
        {brandName}
      </div>
    </Link>
  )
}

export default DashFlowNav
