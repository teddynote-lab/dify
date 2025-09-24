'use client'
import type { FC } from 'react'
import React from 'react'
import { useTranslation } from 'react-i18next'
import { RiInformation2Line } from '@remixicon/react'
import Modal from '@/app/components/base/modal'
import Button from '@/app/components/base/button'

type Props = {
  isShow: boolean
  onClose: () => void
}

const PermissionDeniedModal: FC<Props> = ({
  isShow,
  onClose,
}) => {
  const { t } = useTranslation()

  return (
    <Modal
      isShow={isShow}
      onClose={onClose}
      closable
      className='w-[480px]'
      title={
        <div className='flex items-center gap-2'>
          <RiInformation2Line className='text-warning-600 h-5 w-5' />
          <span>{t('plugin.permission.title')}</span>
        </div>
      }
    >
      <div className='flex flex-col gap-4'>
        <div className='text-sm text-text-secondary'>
          {t('plugin.permission.description')}
        </div>
        <div className='text-xs text-text-tertiary'>
          {t('plugin.permission.contact')}
        </div>
        <div className='flex justify-end'>
          <Button
            onClick={onClose}
            variant='primary'
            className='min-w-24'
          >
            {t('common.operation.confirm')}
          </Button>
        </div>
      </div>
    </Modal>
  )
}

export default React.memo(PermissionDeniedModal)
