'use client'
import { useTranslation } from 'react-i18next'
import { Fragment, useMemo, useState } from 'react'
import { useContext } from 'use-context-selector'
import { Menu, MenuButton, MenuItem, MenuItems, Transition } from '@headlessui/react'
import { CheckIcon, ChevronDownIcon, ClipboardDocumentIcon, EnvelopeIcon, KeyIcon } from '@heroicons/react/24/outline'
import { useProviderContext } from '@/context/provider-context'
import cn from '@/utils/classnames'
import type { Member } from '@/models/common'
import { deleteMemberOrCancelInvitation, resetMemberPassword, updateMemberRole } from '@/service/common'
import { ToastContext } from '@/app/components/base/toast'
import Modal from '@/app/components/base/modal'
import Button from '@/app/components/base/button'

type IOperationProps = {
  member: Member
  operatorRole: string
  onOperate: () => void
}

const Operation = ({
  member,
  operatorRole,
  onOperate,
}: IOperationProps) => {
  const { t } = useTranslation()
  const { datasetOperatorEnabled } = useProviderContext()
  const RoleMap = {
    owner: t('common.members.owner'),
    admin: t('common.members.admin'),
    editor: t('common.members.editor'),
    normal: t('common.members.normal'),
    dataset_operator: t('common.members.datasetOperator'),
  }
  const roleList = useMemo(() => {
    if (operatorRole === 'owner') {
      return [
        ...['admin', 'editor', 'normal'],
        ...(datasetOperatorEnabled ? ['dataset_operator'] : []),
      ]
    }
    if (operatorRole === 'admin') {
      return [
        ...['editor', 'normal'],
        ...(datasetOperatorEnabled ? ['dataset_operator'] : []),
      ]
    }
    return []
  }, [operatorRole, datasetOperatorEnabled])
  const { notify } = useContext(ToastContext)
  const [showResetPasswordModal, setShowResetPasswordModal] = useState(false)
  const [showPasswordSuccessModal, setShowPasswordSuccessModal] = useState(false)
  const [generatedPassword, setGeneratedPassword] = useState('')
  const [isCopied, setIsCopied] = useState(false)
  const [isSendingEmail, setIsSendingEmail] = useState(false)
  const toHump = (name: string) => name.replace(/_(\w)/g, (all, letter) => letter.toUpperCase())

  const generateRandomPassword = () => {
    // Exclude confusing characters (0, O, o, 1, I, i, l)
    const letters = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz'
    const numbers = '23456789'

    // First, select 2 numbers
    let password = ''
    for (let i = 0; i < 2; i++)
      password += numbers.charAt(Math.floor(Math.random() * numbers.length))

    // Then, select 6 letters
    for (let i = 0; i < 6; i++)
      password += letters.charAt(Math.floor(Math.random() * letters.length))

    // Shuffle password characters (Fisher-Yates algorithm)
    const passwordArray = password.split('')
    for (let i = passwordArray.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1))
      const temp = passwordArray[i]
      passwordArray[i] = passwordArray[j]
      passwordArray[j] = temp
    }

    return passwordArray.join('')
  }

  const handleResetPassword = async () => {
    const newPassword = generateRandomPassword()
    try {
      await resetMemberPassword({
        url: `/workspaces/current/members/${member.id}/reset-password`,
        body: { password: newPassword },
      })
      setGeneratedPassword(newPassword)
      setShowResetPasswordModal(false)
      setShowPasswordSuccessModal(true)
      setIsCopied(false)
    }
 catch (error) {
      notify({ type: 'error', message: t('common.actionMsg.actionFailed') })
      setShowResetPasswordModal(false)
    }
  }

  const handleCopyPassword = async () => {
    try {
      await navigator.clipboard.writeText(generatedPassword)
      setIsCopied(true)
      notify({ type: 'success', message: t('common.actionMsg.copySuccessfully') })
      setTimeout(() => setIsCopied(false), 2000)
    }
 catch (error) {
      notify({ type: 'error', message: t('common.actionMsg.copyFailed') })
    }
  }

  const handleSendEmail = async () => {
    setIsSendingEmail(true)
    try {
      await resetMemberPassword({
        url: `/workspaces/current/members/${member.id}/reset-password`,
        body: { password: generatedPassword, send_email: true },
      })
      notify({ type: 'success', message: t('common.members.passwordEmailSent') })
      setShowPasswordSuccessModal(false)
    }
 catch (error) {
      notify({ type: 'error', message: t('common.members.passwordEmailFailed') })
    }
 finally {
      setIsSendingEmail(false)
    }
  }

  const handleDeleteMemberOrCancelInvitation = async () => {
    try {
      await deleteMemberOrCancelInvitation({ url: `/workspaces/current/members/${member.id}` })
      onOperate()
      notify({ type: 'success', message: t('common.actionMsg.modifiedSuccessfully') })
    }
    catch {

    }
  }
  const handleUpdateMemberRole = async (role: string) => {
    try {
      await updateMemberRole({
        url: `/workspaces/current/members/${member.id}/update-role`,
        body: { role },
      })
      onOperate()
      notify({ type: 'success', message: t('common.actionMsg.modifiedSuccessfully') })
    }
    catch {

    }
  }

  return (
    <>
    <Menu as="div" className="relative h-full w-full">
      {
        ({ open }) => (
          <>
            <MenuButton className={cn('system-sm-regular group flex h-full w-full cursor-pointer items-center justify-between px-3 text-text-secondary hover:bg-state-base-hover', open && 'bg-state-base-hover')}>
              {RoleMap[member.role] || RoleMap.normal}
              <ChevronDownIcon className={cn('h-4 w-4 group-hover:block', open ? 'block' : 'hidden')} />
            </MenuButton>
            <Transition
              as={Fragment}
              enter="transition ease-out duration-100"
              enterFrom="transform opacity-0 scale-95"
              enterTo="transform opacity-100 scale-100"
              leave="transition ease-in duration-75"
              leaveFrom="transform opacity-100 scale-100"
              leaveTo="transform opacity-0 scale-95"
            >
              <MenuItems
                className={cn('absolute right-0 top-[52px] z-10 origin-top-right rounded-xl border-[0.5px] border-components-panel-border bg-components-panel-bg-blur shadow-lg backdrop-blur-sm')}
              >
                <div className="p-1">
                  {
                    roleList.map(role => (
                      <MenuItem key={role}>
                        <div className='flex cursor-pointer rounded-lg px-3 py-2 hover:bg-state-base-hover' onClick={() => handleUpdateMemberRole(role)}>
                          {
                            role === member.role
                              ? <CheckIcon className='mr-1 mt-[2px] h-4 w-4 text-text-accent' />
                              : <div className='mr-1 mt-[2px] h-4 w-4 text-text-accent' />
                          }
                          <div>
                            <div className='system-sm-semibold whitespace-nowrap text-text-secondary'>{t(`common.members.${toHump(role)}`)}</div>
                            <div className='system-xs-regular whitespace-nowrap text-text-tertiary'>{t(`common.members.${toHump(role)}Tip`)}</div>
                          </div>
                        </div>
                      </MenuItem>
                    ))
                  }
                </div>
                <MenuItem>
                  <div className='border-t border-divider-subtle p-1'>
                    <div className='flex cursor-pointer rounded-lg px-3 py-2 hover:bg-state-base-hover' onClick={() => setShowResetPasswordModal(true)}>
                      <KeyIcon className='mr-1 mt-[2px] h-4 w-4 text-text-accent' />
                      <div>
                        <div className='system-sm-semibold whitespace-nowrap text-text-secondary'>{t('common.members.resetPasswordBtn')}</div>
                        <div className='system-xs-regular whitespace-nowrap text-text-tertiary'>{t('common.members.resetPasswordTip')}</div>
                      </div>
                    </div>
                  </div>
                </MenuItem>
                <MenuItem>
                  <div className='p-1'>
                    <div className='flex cursor-pointer rounded-lg px-3 py-2 hover:bg-state-base-hover' onClick={handleDeleteMemberOrCancelInvitation}>
                      <div className='mr-1 mt-[2px] h-4 w-4 text-text-accent' />
                      <div>
                        <div className='system-sm-semibold whitespace-nowrap text-text-secondary'>{t('common.members.removeFromTeam')}</div>
                        <div className='system-xs-regular whitespace-nowrap text-text-tertiary'>{t('common.members.removeFromTeamTip')}</div>
                      </div>
                    </div>
                  </div>
                </MenuItem>
              </MenuItems>
            </Transition>
          </>
        )
      }
    </Menu>
    {showResetPasswordModal && (
      <Modal
        isShow={showResetPasswordModal}
        onClose={() => setShowResetPasswordModal(false)}
        title={t('common.members.resetPasswordBtn')}
      >
        <div className='mb-4'>
          <p>{t('common.members.resetPasswordConfirm')}</p>
        </div>
        <div className='flex gap-2'>
          <Button onClick={() => setShowResetPasswordModal(false)} variant='secondary'>
            {t('common.operation.cancel')}
          </Button>
          <Button onClick={handleResetPassword} variant='primary'>
            {t('common.operation.confirm')}
          </Button>
        </div>
      </Modal>
    )}
    {showPasswordSuccessModal && (
      <Modal
        isShow={showPasswordSuccessModal}
        onClose={() => setShowPasswordSuccessModal(false)}
        title={t('common.members.passwordResetSuccess')}
      >
        <div className='mb-6'>
          <p className='mb-4 text-text-secondary'>{t('common.members.passwordResetSuccessDesc')}</p>
          <div className='rounded-lg bg-state-base-hover p-4'>
            <div className='flex items-center justify-between'>
              <div>
                <p className='mb-1 text-xs text-text-tertiary'>{t('common.members.newPassword')}</p>
                <p className='select-all font-mono text-lg font-semibold text-text-primary'>{generatedPassword}</p>
              </div>
              <Button
                onClick={handleCopyPassword}
                variant='ghost'
                className='!p-2'
              >
                {isCopied ? (
                  <CheckIcon className='h-5 w-5 text-text-accent' />
                ) : (
                  <ClipboardDocumentIcon className='h-5 w-5 text-text-secondary' />
                )}
              </Button>
            </div>
          </div>
          <p className='mt-4 rounded-lg bg-state-warning-hover p-3 text-sm text-text-warning'>
            {t('common.members.passwordSecurityWarning')}
          </p>
        </div>
        <div className='flex justify-between'>
          <Button
            onClick={handleSendEmail}
            variant='secondary'
            disabled={isSendingEmail}
            className='flex items-center gap-2'
          >
            <EnvelopeIcon className='h-4 w-4' />
            {isSendingEmail ? t('common.members.sendingEmail') : t('common.members.sendViaEmail')}
          </Button>
          <Button onClick={() => setShowPasswordSuccessModal(false)} variant='primary'>
            {t('common.operation.ok')}
          </Button>
        </div>
      </Modal>
    )}
    </>
  )
}

export default Operation
