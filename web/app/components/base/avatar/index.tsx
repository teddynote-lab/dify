'use client'
import cn from '@/utils/classnames'

export type AvatarProps = {
  name: string
  avatar?: string | null
  size?: number
  className?: string
  textClassName?: string
  onError?: (x: boolean) => void
}
const Avatar = ({
  name,
  size = 30,
  className,
}: AvatarProps) => {
  const avatarClassName = 'shrink-0 flex items-center rounded-full bg-white'
  const style = { width: `${size}px`, height: `${size}px`, fontSize: `${size}px`, lineHeight: `${size}px` }

  // Always use the fixed profile image
  return (
    <img
      className={cn(avatarClassName, className)}
      style={style}
      alt={name}
      src="/branding/profile.svg"
    />
  )
}

export default Avatar
